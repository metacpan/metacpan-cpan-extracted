package App::Koyomi::DataSource::Job::Teng;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/teng/],
);
use DateTime::Format::MySQL;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Smart::Args;

use App::Koyomi::DataSource::Job::Teng::Data;
use App::Koyomi::DataSource::Job::Teng::Object;
use App::Koyomi::DataSource::Job::Teng::Schema;

use parent qw(App::Koyomi::DataSource::Job);

use version; our $VERSION = 'v0.6.0';

my $DATASOURCE;

sub instance {
    args(
        my $class,
        my $ctx => 'App::Koyomi::Context',
    );
    $DATASOURCE //= sub {
        my $connector
            = $ctx->config->{datasource}{connector}{job}
            // $ctx->config->{datasource}{connector};
        my $teng = App::Koyomi::DataSource::Job::Teng::Object->new(
            connect_info => [
                $connector->{dsn}, $connector->{user}, $connector->{password},
                +{ RaiseError => 1, PrintError => 0, AutoCommit => 1 },
            ],
            schema => App::Koyomi::DataSource::Job::Teng::Schema->instance,
        );
        my %obj = (teng => $teng);
        return bless \%obj, $class;
    }->();
    return $DATASOURCE;
}

sub gets {
    args(
        my $self,
        my $ctx => 'App::Koyomi::Context',
    );

    my @jobs  = $self->teng->search('jobs'      => +{})->all;
    my @times = $self->teng->search('job_times' => +{})->all;

    my @data;
    for my $job (@jobs) {
        my @_t = grep { $_->job_id == $job->id } @times;
        my $d  = App::Koyomi::DataSource::Job::Teng::Data->new(
            ctx   => $ctx,
            job   => $job,
            times => \@_t,
        );
        push(@data, $d);
    }

    return @data;
}

sub get_by_id {
    args(
        my $self,
        my $id  => 'Int',
        my $ctx => 'App::Koyomi::Context',
    );

    my $job = $self->teng->single('jobs' => +{ id => $id });
    return unless $job;
    my @times = $self->teng->search('job_times' => +{ job_id => $id })->all;
    unless (@times) {
        warnf(q/Job id=%d has no times records./, $id);
    }

    return App::Koyomi::DataSource::Job::Teng::Data->new(
        ctx   => $ctx,
        job   => $job,
        times => \@times,
    );
}

sub create {
    args(
        my $self,
        my $data => 'HashRef',
        my $ctx  => 'App::Koyomi::Context',
        my $now  => +{ isa => 'DateTime', optional => 1 },
    );
    $now ||= $ctx->now;
    my $teng = $self->teng;

    # Transaction
    my $txn = $teng->txn_scope;

    my $now_db = DateTime::Format::MySQL->format_datetime($now);
    eval {
        # create jobs
        my %job = map { $_ => $data->{$_} } qw/user command memo/;
        $job{created_on} = $job{updated_at} = $now_db;
        my $new_job = $teng->insert('jobs', \%job);
        unless ($new_job) {
            croakf(q/Insert jobs Failed! data=%s/, ddf(\%job));
        }

        # create job_times
        for my $t (@{$data->{times}}) {
            my %time = (
                job_id => $new_job->id,
                %$t,
                created_on => $now_db,
                updated_at => $now_db,
            );
            $teng->insert('job_times', \%time)
                or croakf(q/Insert job_times Failed! data=%s/, ddf(\%time));
        }

        # Initialize semaphore
        $ctx->datasource_semaphore->create(
            job_id => $new_job->id, ctx => $ctx, now => $now);
    };
    if ($@) {
        $txn->rollback;
        die $@;
    }

    $txn->commit;
    return 1;
}

sub update_by_id {
    args(
        my $self,
        my $id   => 'Int',
        my $data => 'HashRef',
        my $ctx  => 'App::Koyomi::Context',
        my $now  => +{ isa => 'DateTime', optional => 1 },
    );
    $now ||= $ctx->now;
    my $teng = $self->teng;

    # Transaction
    my $txn = $teng->txn_scope;

    my $now_db = DateTime::Format::MySQL->format_datetime($now);
    eval {
        # update jobs
        my %job = map { $_ => $data->{$_} } qw/user command memo/;
        $job{updated_at} = $now_db;
        unless ($teng->update('jobs', \%job, +{ id => $id })) {
            croakf(q/Update jobs Failed! id=%d, data=%s/, $id, ddf(\%job));
        }

        # replace job_times
        unless ($teng->delete('job_times', +{ job_id => $id })) {
            croakf(q/Delete job_times Failed! id=%d/, $id);
        }
        for my $t (@{$data->{times}}) {
            my %time = (
                job_id => $id,
                %$t,
                created_on => $now_db,
                updated_at => $now_db,
            );
            $teng->insert('job_times', \%time)
                or croakf(q/Insert job_times Failed! data=%s/, ddf(\%time));
        }
    };
    if ($@) {
        $txn->rollback;
        die $@;
    }

    $txn->commit;
    return 1;
}

sub delete_by_id {
    args(
        my $self,
        my $id  => 'Int',
        my $ctx => 'App::Koyomi::Context',
    );
    my $teng = $self->teng;

    # Transaction
    my $txn = $teng->txn_scope;

    eval {
        unless ($teng->delete('jobs', +{ id => $id })) {
            croakf(q/Delete jobs Failed! id=%d/, $id);
        }
        unless ($teng->delete('job_times', +{ job_id => $id })) {
            croakf(q/Delete job_times Failed! id=%d/, $id);
        }
        # Clean up semaphore
        $ctx->datasource_semaphore->delete_by_job_id(job_id => $id, ctx => $ctx);
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

App::Koyomi::DataSource::Job::Teng - Teng interface as job datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Job::Teng;
    my $ds = App::Koyomi::DataSource::Job::Teng->instance(ctx => $ctx);
    my @jobs = $ds->gets

=head1 DESCRIPTION

Teng interface as datasource for koyomi job schedule.
Subclass of L<App::Koyomi::DataSource::Job>.

=head1 METHODS

See L<App::Koyomi::DataSource::Job>.

=head1 SEE ALSO

L<Teng>

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

