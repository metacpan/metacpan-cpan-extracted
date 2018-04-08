package App::Koyomi::DataSource::Semaphore::Teng::Data;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/row ctx/],
);
use DateTime::Format::MySQL;
use Smart::Args;

use version; our $VERSION = 'v0.6.1';

{
    no strict 'refs';
    for my $column (qw/job_id number run_host run_pid/) {
        *{ __PACKAGE__ . '::' . $column } = sub {
            my $self = shift;
            $self->row->$column;
        };
    }
    # DATETIME => DateTime
    for my $column (qw/created_on run_date updated_at/) {
        *{ __PACKAGE__ . '::' . $column } = sub {
            my $self = shift;
            DateTime::Format::MySQL->parse_datetime($self->row->$column)
                ->set_time_zone($self->ctx->config->time_zone);
        };
    }
}

sub new {
    args(
        my $class,
        my $row => 'Teng::Row',
        my $ctx => 'App::Koyomi::Context',
    );
    bless +{
        row => $row,
        ctx => $ctx,
    }, $class;
}

sub update_with_condition {
    args(
        my $self,
        my $data  => 'HashRef',
        my $where => 'HashRef',
        my $ctx   => 'App::Koyomi::Context',
        my $now   => +{ isa => 'DateTime', optional => 1 },
    );
    $now ||= $ctx->now;
    my $teng = $self->row->handle;

    my %stash = %$data;
    my %cond  = %$where;
    for my $col (qw/created_on run_date updated_at/) {
        if ($where->{$col}) {
            $cond{$col} = DateTime::Format::MySQL->format_datetime($where->{$col});
        }
        if ($col eq 'updated_at') {
            $stash{$col} = DateTime::Format::MySQL->format_datetime($now);
            next;
        }
        if ($data->{$col}) {
            $stash{$col} = DateTime::Format::MySQL->format_datetime($data->{$col});
        }
    }

    my $txn = $teng->txn_scope;
    my $updated = $self->row->update(\%stash, \%cond);
    if ($updated) {
        $txn->commit;
        return 1;
    } else {
        $txn->rollback;
        return 0;
    }

}

1;
__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Semaphore::Teng::Data - Wrapper class to represents a record of semaphore datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Semaphore::Teng::Data;
    my $data = App::Koyomi::DataSource::Semaphore::Teng::Data->new(
        row => $row, # Teng::Row
        ctx => $ctx, # App::Koyomi::Context
    );

=head1 DESCRIPTION

Wrapper class of I<Teng::Row> for semaphore datasource.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Semaphore::Teng>,
L<Teng::Row>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

