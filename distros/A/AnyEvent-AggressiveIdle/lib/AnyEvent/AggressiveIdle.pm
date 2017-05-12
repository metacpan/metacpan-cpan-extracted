package AnyEvent::AggressiveIdle;

use Carp;
use AnyEvent;
use AnyEvent::Util;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION        = '0.04';

our @EXPORT         = qw(aggressive_idle);
our @EXPORT_OK      = qw(stop_aggressive_idle aggressive_idle);
our %EXPORT_TAGS    = ( all => [@EXPORT_OK] );

sub stop_aggressive_idle($) {
    our (%IDLE, $WATCHER);

    my ($no) = @_;

    croak "Invalid idle identifier: $no"
        unless $no and !ref($no) and exists $IDLE{$no};

    delete $IDLE{$no};
    undef $WATCHER unless %IDLE;
    return;
}

sub _watcher
{
    our ($WATCHER, $WOBJ, %IDLE);
    # localize keys (because idle processes can change
    # watchers list)
    my @pid = keys %IDLE;
    for my $p (@pid) {
        next unless exists $IDLE{$p};
        next unless defined $IDLE{$p};

        my $cb = $IDLE{$p};
        $IDLE{$p} = undef;

        my $done = 0;
        {
            my $guard = guard {
                $done = 1;
                # do not restart idle process if user has stopped it
                if (exists $IDLE{$p}) {
                    $IDLE{$p} = $cb;
                    return if $WATCHER;
                    $WATCHER = AE::io $WOBJ, 1, \&_watcher;
                }
            };
            $cb->($p, $guard);
        }

        unless ($done) {
            undef $WATCHER unless %IDLE;
        }
    }
}

sub aggressive_idle(&) {
    our ($WOBJ, $WOBJR, %IDLE, $WATCHER, $NO);
    ($WOBJR, $WOBJ) = portable_pipe unless defined $WOBJ;
    $NO = 0 unless defined $NO;

    $WATCHER = AE::io $WOBJ, 1, \&_watcher unless %IDLE;

    my $no = ++$NO;
    $IDLE{$no} = $_[0];

    return unless defined wantarray;
    return guard { stop_aggressive_idle $no };
}



1;
__END__

=head1 NAME

AnyEvent::AggressiveIdle - Aggressive idle processes for AnyEvent.

=head1 SYNOPSIS

    use AnyEvent::AggressiveIdle qw(aggressive_idle};

    aggressive_idle {
        ... do something important
    };


    my $idle;
    $idle = aggressive_idle {
        ... do something important

        if (FINISH) {
            undef $idle;    # do not call the sub anymore
        }
    };

=head1 DESCRIPTION

Sometimes You need to do something that takes much time but can be
split into elementary phases. If You use L<AE::idle|AnyEvent/idle>
and Your program is a highload project, idle process can be delayed
for much time (second, hour, day, etc). L<aggressive_idle> will be
called for each L<AnyEvent> loop cycle. So You can be sure that Your
idle process will continue.

=head1 EXPORTS

=head2 aggressive_idle

Register Your function as aggressive idle watcher. If it is called
in B<VOID> context, the watcher wont be deinstalled. Be carrefully.

In B<NON_VOID> context the function returns a L<guard|AnyEvent::Util/guard>.
Hold the guard until You want to cancel idle process.


=head2 stop_aggressive_idle

You can use the function to stop idle process. The function receives
idle process B<PID> that can be received in idle callback (the first
argument).

Example:

    use AnyEvent::AggressiveIdle ':all'; # or:
    use AnyEvent::AggressiveIdle qw(aggressive_idle stop_aggressive_idle);

    aggressive_idle {
        my ($pid) = @_;
        ....

        stop_aggressive_idle $pid;
    }

The function will throw an exception if invalid PID is received.

=head1 Continuous process.

Sometimes You need to to something continuous inside idle callback. If
You want to stop idle calls until You have done Your work, You can hold
guard inside Your process:

    aggressive_idle {
        my ($pid, $guard) = @_;
        my $timer;
        $timer = AE::timer 0.5, 0 => sub {
            undef $timer;
            undef $guard;   # POINT 1
        }
    }

Until 'B<POINT 1>' aggressive_idle won't call its callback.
Feel free to L<stop_aggressive_idle> before free the guard.

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 VCS

The project is placed on my GIT repo:
L<http://git.uvw.ru/?p=anyevent-aggressiveidle;a=summary>

=cut
