package App::Koyomi::DataSource::Job::Teng::Data;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ctx times/],
);
use Smart::Args;

use version; our $VERSION = 'v0.6.0';

use App::Koyomi::DataSource::Job::Teng::JobTime;

# Accessor for jobs.columns
{
    no strict 'refs';
    for my $column (qw/id user command memo/) {
        *{ __PACKAGE__ . '::' . $column } = sub {
            my $self = shift;
            $self->{_job}->$column;
        };
    }
    # DATETIME => DateTime
    for my $column (qw/created_on updated_at/) {
        *{ __PACKAGE__ . '::' . $column } = sub {
            my $self = shift;
            DateTime::Format::MySQL->parse_datetime($self->{_job}->$column)
                ->set_time_zone($self->ctx->config->time_zone);
        };
    }
}

sub new {
    args(
        my $class,
        my $ctx   => 'App::Koyomi::Context',
        my $job   => 'Teng::Row',
        my $times => 'ArrayRef[Teng::Row]',
    );
    my @my_times;
    for my $time (@$times) {
        my $my_t = App::Koyomi::DataSource::Job::Teng::JobTime->new(row => $time);
        push(@my_times, $my_t);
    }

    bless +{
        _job  => $job,
        times => \@my_times,
        ctx   => $ctx,
    }, $class;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Koyomi::DataSource::Job::Teng::Data - Wrapper class to represents a record of job datasource

=head1 SYNOPSIS

    use App::Koyomi::DataSource::Job::Teng::Data;
    my $data = App::Koyomi::DataSource::Job::Teng::Data->new(
        ctx   => $ctx,   # App::Koyomi::Context
        job   => $job,   # Teng::Row (`jobs` table)
        times => $times, # ArrayRef[Teng::Row] (`job_times` table)
    );

=head1 DESCRIPTION

Wrapper class of I<Teng::Row> for job datasource.

=head1 SEE ALSO

L<App::Koyomi::DataSource::Job::Teng>,
L<Teng::Row>

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

