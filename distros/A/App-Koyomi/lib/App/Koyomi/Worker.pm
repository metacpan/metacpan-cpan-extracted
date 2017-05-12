package App::Koyomi::Worker;

use strict;
use warnings;
use 5.010_001;
use Class::Accessor::Lite (
    ro => [qw/ctx config schedule/],
);
use DateTime;
use Getopt::Long qw(:config posix_default no_ignore_case no_ignore_case_always);
use Log::Minimal env_debug => 'KOYOMI_LOG_DEBUG';
use Proc::Wait3;
use Smart::Args;
use Time::Piece;

use App::Koyomi::Context;
use App::Koyomi::Schedule;

use version; our $VERSION = 'v0.6.0';

sub new {
    args(
        my $class,
        my $config => +{ isa => 'Str',  optional => 1 },
        my $debug  => +{ isa => 'Bool', optional => 1 },
    );
    $ENV{KOYOMI_CONFIG_PATH} = $config if $config;
    $ENV{KOYOMI_LOG_DEBUG}   = 1       if $debug;

    my $ctx   = App::Koyomi::Context->instance;
    return bless +{
        ctx      => $ctx,
        config   => $ctx->config,
        schedule => App::Koyomi::Schedule->instance(ctx => $ctx),
    }, $class;
}

sub parse_args {
    my $class  = shift;
    my @args   = @_;

    Getopt::Long::GetOptionsFromArray(
        \@args, \my %opt, 'config|c=s',
        'debug|d', 'help|h', 'man',
    );
    return \%opt;
}

sub run {
    my $self = shift;

    my $now = $self->_now;

    ## main loop
    while (1) {
        $self->schedule->update($now);
        my @jobs = $self->schedule->get_jobs($now);

        for my $job (@jobs) {
            my $pid = fork();
            if ($pid == 0) { # child
                $job->proceed($now);
                exit;
            } elsif ($pid) { # parent
                # nothing to do
            } else {
                die "Can't fork: $!";
            }
        }

        my $prev_epoch = $now->epoch;
        $now->add(
            minutes => $self->config->{worker}{interval_minutes}
        )->truncate(to => 'minute');

        # Sleep to next tick
        my $min_seconds = $self->config->{worker}{minimum_interval_seconds};
        my $seconds = $now->epoch - $prev_epoch;
        if ($seconds < $min_seconds) {
            my $dsec = $min_seconds - $seconds;
            $seconds = $min_seconds;
            $now->add(seconds => $dsec);
        }
        if ($self->ctx->is_debug) {
            $seconds = $self->config->{debug}{worker}{sleep_seconds} // $seconds;
        }
        sleep($seconds);
        while (my @child_proc_info = wait3(0)) {
            debugf('Exit %d', $child_proc_info[0]);
        }
    }
}

sub _now {
    my $self = shift;

    my $debug_datestr = sub {
        return unless $self->ctx->is_debug;
        return $self->config->{debug}{now} // undef;
    }->();
    if ($debug_datestr) {
        my $t = Time::Piece->strptime($debug_datestr, '%Y-%m-%dT%H:%M');
        return DateTime->from_epoch(epoch => $t->epoch);
    }
    return $self->ctx->now;
}

1;

__END__

=encoding utf8

=head1 NAME

B<App::Koyomi::Worker> - koyomi worker module

=head1 SYNOPSIS

    use App::Koyomi::Worker;
    my $props = App::Koyomi::Worker->parse_args(@ARGV);
    App::Koyomi::Worker->new(%$props)->run;

=head1 DESCRIPTION

I<Koyomi> worker module.

=head1 METHODS

=over 4

=item B<new>

Construction.

=item B<run>

Runs worker.

=item B<parse_args> : HashRef

Parse command-line arguments.
Return option stash to construct the worker object or to show help.

=back

=head1 SEE ALSO

L<koyomi>,
L<App::Koyomi::Context>

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2015 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

