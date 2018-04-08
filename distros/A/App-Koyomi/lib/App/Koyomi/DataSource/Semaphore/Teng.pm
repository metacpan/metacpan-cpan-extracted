package App::Koyomi::DataSource::Semaphore::Teng;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/teng/],
);
use DateTime::Format::MySQL;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Smart::Args;

use App::Koyomi::DataSource::Semaphore::Teng::Data;
use App::Koyomi::DataSource::Semaphore::Teng::Object;
use App::Koyomi::DataSource::Semaphore::Teng::Schema;

use parent qw(App::Koyomi::DataSource::Semaphore);

use version; our $VERSION = 'v0.6.1';

my $TABLE = 'semaphores';
my $DATASOURCE;

sub instance {
    args(
        my $class,
        my $ctx => 'App::Koyomi::Context',
    );
    $DATASOURCE //= sub {
        my $connector
            = $ctx->config->{datasource}{connector}{semaphore}
            // $ctx->config->{datasource}{connector};
        my $teng = App::Koyomi::DataSource::Semaphore::Teng::Object->new(
            connect_info => [
                $connector->{dsn}, $connector->{user}, $connector->{password},
                +{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
            ],
            schema => App::Koyomi::DataSource::Semaphore::Teng::Schema->instance,
        );
        my %obj = (teng => $teng);
        return bless \%obj, $class;
    }->();
    return $DATASOURCE;
}

sub get_by_job_id {
    args(
        my $self,
        my $job_id => 'Int',
        my $ctx    => 'App::Koyomi::Context',
    );
    my $row = $self->teng->single($TABLE, +{job_id => $job_id});
    return unless $row;
    return App::Koyomi::DataSource::Semaphore::Teng::Data->new(
        row => $row,
        ctx => $ctx,
    );
}

sub create {
    args(
        my $self,
        my $job_id => 'Int',
        my $ctx    => 'App::Koyomi::Context',
        my $now    => +{ isa => 'DateTime', optional => 1 },
    );
    $now ||= $ctx->now;
    my $teng = $self->teng;

    # Transaction
    my $txn = $teng->txn_scope;

    my $now_db = DateTime::Format::MySQL->format_datetime($now);
    eval {
        my %semaphore = ( job_id => $job_id );
        $semaphore{created_on} = $semaphore{updated_at} = $now_db;
        unless ($teng->insert($TABLE, \%semaphore)) {
            croakf(q/Insert %s Failed! data=%s/, $TABLE, ddf(\%semaphore));
        }
    };
    if ($@) {
        $txn->rollback;
        die $@;
    }

    $txn->commit;
    return 1;
}

sub delete_by_job_id {
    args(
        my $self,
        my $job_id => 'Int',
        my $ctx    => 'App::Koyomi::Context',
    );
    my $teng = $self->teng;

    # Transaction
    my $txn = $teng->txn_scope;

    eval {
        unless ($teng->delete($TABLE, +{ job_id => $job_id })) {
            croakf(q/Delete %s Failed! job_id=%d/, $TABLE, $job_id);
        }
    };
    if ($@) {
        $txn->rollback;
        die $@;
    }

    $txn->commit;
    return 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Semaphore::Teng - Teng interface as semaphore datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Semaphore::Teng;
    my $ds = App::Koyomi::DataSource::Semaphore::Teng->instance(ctx => $ctx);

=head1 DESCRIPTION

Teng interface as datasource for koyomi semaphore.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Semaphore>,
L<Teng>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

