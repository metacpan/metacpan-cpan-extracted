package App::Koyomi::Schedule;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ctx config jobs/],
    rw => [qw/last_updated_at/],
);
use DateTime;
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Smart::Args;

use App::Koyomi::Job;

use version; our $VERSION = 'v0.6.1';

my $SCHEDULE;

sub instance {
    args(
        my $class,
        my $ctx => 'App::Koyomi::Context',
    );
    $SCHEDULE //= sub {
        my %obj = (
            ctx             => $ctx,
            config          => $ctx->config,
            jobs            => undef,
            last_updated_at => 0,
        );
        return bless \%obj, $class;
    }->();
    return $SCHEDULE;
}

sub update {
    my $self = shift;
    my $now  = shift // $self->ctx->now;

    if ($now->epoch - $self->last_updated_at < $self->config->{schedule}{update_interval_seconds}) {
        debugf('no need to update schedule');
        return;
    }

    debugf('update schedule');
    $self->_update_jobs && $self->last_updated_at($now->epoch);
    #debugf(ddf($self->jobs));
}

sub _update_jobs {
    my $self = shift;
    my $jobs = eval {
        App::Koyomi::Job->get_jobs(ctx => $self->ctx);
    };
    if ($@) {
        critf('FAILED to fetch jobs!! ERROR = %s', $@);
        return 0;
    }
    $self->{jobs} = $jobs;
    return 1;
}

sub get_jobs {
    my $self = shift;
    my $now  = shift // $self->ctx->now;
    debugf($now->strftime('%FT%T %a'));

    # Fetch scheduled jobs
    return _filter_current_jobs($self->jobs, $now);
}

sub _filter_current_jobs {
    my ($all_jobs, $now) = @_;

    my @matched;
    for my $job (@$all_jobs) {
        if ( _filter_job_times($job->times, $now) ) {
            push(@matched, $job);
        }
    }
    return @matched;
}

sub _filter_job_times {
    my ($times, $now) = @_;

    # all conditions but day and day-of-week
    my @jobs = grep {
           ( $_->year   eq '*' || $_->year   == $now->year   )
        && ( $_->month  eq '*' || $_->month  == $now->month  )
        && ( $_->hour   eq '*' || $_->hour   == $now->hour   )
        && ( $_->minute eq '*' || $_->minute == $now->minute )
    } @$times;

    # day and day-of-week conditions
    @jobs = grep {
           ( $_->day     eq '*'     && $_->weekday eq '*' )
        || ( $_->day     =~ /^\d+$/ && $_->day     == $now->day )
        || ( $_->weekday =~ /^\d+$/ && $_->weekday == $now->day_of_week )
    } @jobs;

    return @jobs;
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Schedule> - koyomi job schedule

=head1 SYNOPSIS

    use App::Koyomi::Schedule;
    my $schedule = App::Koyomi::Schedule->instance;

=head1 DESCRIPTION

This module represents Singleton schedule object.

=head1 METHODS

=over 4

=item B<instance>

Fetch schedule singleton.

=item B<update>

Update schedule if needed.

=item B<get_jobs> (DateTime)

Fetch jobs to execute at that time.

=back

=head1 SEE ALSO

L<App::Koyomi::Worker>

=head1 AUTHORS

IKEDA Kiyoshi E<lt>progrhyme@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015-2017 IKEDA Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

