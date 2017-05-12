package App::MultiModule::Tasks::ResourceWatcher;
$App::MultiModule::Tasks::ResourceWatcher::VERSION = '1.161190';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Message::Transform qw(mtransform);
use P9Y::ProcessTable;
use Storable;
use POSIX ":sys_wait_h";

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::ResourceWatcher - Manage process resources under App::MultiModule

=cut

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    my $state = $self->{state};
    my $state_watches = $state->{watches};
    if($message->{watches}) {
        mtransform($state_watches, $message->{watches});
    }
}

sub _get_processes {
    my $self = shift;
    my $ret = {};
    my $ts = time;
    foreach my $process (P9Y::ProcessTable->table) {
        $process->{process_uptime} = $ts - $process->{start};
        $ret->{$process->{pid}} = $process;
    }
    return $ret;
}

sub _fire {
    my $self = shift;
    my $level = shift;
    my $watch_name = shift;
    my $pid = shift;
    my $message = {
        resourceWatcher_level => $level->{level_number},
        watch_name => $watch_name,
    };
    delete $level->{level_number};
    $message->{resourceWatcher} = Storable::dclone($level);
    mtransform($message, $level->{transform})
        if $level->{transform};
    if(my $actions = $level->{actions}) {
        if($actions->{signal}) {
            #we could look at the return value of kill, but if it's zero,
            #that just means that the process exited beween the time we
            #gathered all of the processes and now, which is something that
            #will happen from time to time and isn't notable
            kill $actions->{signal}, $pid;
            $message->{resourceWatcher_signal_sent} = $actions->{signal};
        } else {
            $self->error("App::MultiModule::Tasks::ResourceWatcher::_fire: called action must currently have a signal attribute. \$watch_name=$watch_name \$level_number=$message->{resourceWatcher_level}");
        }
    }
    $self->emit($message);
}

sub _tick {
    my $self = shift;
    my $watches = Storable::dclone($self->{config}->{watches});
    my $state_watches = $self->{state}->{watches};
    mtransform($watches, $state_watches);
    my $timeout = $self->{config}->{tick_timeout} || 1;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm $timeout;
        my $processes = $self->_get_processes;

        WATCH:
        foreach my $watch_name (keys %$watches) {
            my $watch = $watches->{$watch_name};
            $watch->{levels} = {} unless $watch->{levels};
            if(my $pid = $watch->{resourceWatcher_PID}) {
                my $process_info = $processes->{$pid};
                if(not $process_info) { #the process is gone
                    if($watch->{no_process}) {
                        my $message = {
                            watch_name => $watch_name,
                        };
                        mtransform($message, $watch->{no_process}->{transform})
                            if $watch->{no_process}->{transform};
                        $self->emit($message);
                    }
                    delete $state_watches->{$watch_name};
                    next WATCH;
                }
                #sort numerically descending
                LEVEL:
                foreach my $level_number (sort { $b <=> $a } keys %{$watch->{levels}}) {
                    my $level = $watch->{levels}->{$level_number};
                    $level->{level_number} = $level_number;
                    if(my $floor = $level->{floor}) {
                        my $fire = 1;
                        foreach my $floor_field (keys %$floor) {
                            if(not defined $process_info->{$floor_field}) {
                                $self->error("App::MultiModule::Tasks::ResourceWatcher::_tick: referenced floor_field does not exist in process_info \$watch_name=$watch_name \$level_number=$level_number \$floor_field=$floor_field \$process_info=" . Data::Dumper::Dumper $process_info);
                                last;
                            }
                            #we will not fire if any field in the process
                            #is below the defined floor
                            if($process_info->{$floor_field} < $floor->{$floor_field}) {
                                $fire = 0;
                            }
                        }
                        if($fire) {
                            $self->_fire($level, $watch_name, $pid);
                            last LEVEL;
                        }
                    } else {
                        $self->error("App::MultiModule::Tasks::ResourceWatcher::_tick: we currently require each level of each watch to have a floor field \$watch_name=$watch_name \$level_number=$level_number");
                    }
                }
            } else {
                $self->error("App::MultiModule::Tasks::ResourceWatcher::_tick: we currently require each watch to have a resourceWatcher_PID field  \$watch_name=$watch_name");
            }
        }
    };
    if($@) {
        $self->error("App::MultiModule::Tasks::ResourceWatcher::_tick: general exception: $@");
    }
    alarm 0;
}
=head1 cut
$VAR1 = [
          bless( {
                   '_pt_obj' => bless( {}, 'P9Y::ProcessTable::Table' ),
                   'priority' => '20',
                   'uid' => 0,
                   'sess' => '1',
                   'environ' => {
                                  'PATH' => '/sbin:/usr/sbin:/bin:/usr/bin',
                                  'recovery' => '',
                                },
                   'majflt' => 54,
                   'cwd' => '/'
                 }, 'P9Y::ProcessTable::Process' ),
          bless( {
=cut


=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->{config}->{watches} = {} unless $self->{config}->{watches};
    $self->{state} = {} unless $self->{state};
    $self->{state}->{watches} = {} unless $self->{state}->{watches};
    $self->named_recur(
        recur_name => 'ResourceWatcher_reap-zombies',
        repeat_interval => 1,
        work => sub {
            my $kid;
            do {
                $kid = waitpid(-1, WNOHANG);
            } while $kid > 0;
        }
    );
    $self->named_recur(
        recur_name => 'ResourceWatcher_tick',
        repeat_interval => 1,
        work => sub {
            $self->_tick;
        }
    );
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'TODO: maybe?';
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-ResourceWatcher/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::ResourceWatcher


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-ResourceWatcher/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-ResourceWatcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-ResourceWatcher>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::ResourceWatcher>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::MultiModule::Tasks::ResourceWatcher
