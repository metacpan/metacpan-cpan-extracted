package App::MultiModule::Tasks::Scheduler;
$App::MultiModule::Tasks::Scheduler::VERSION = '1.161950';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Message::Transform qw(mtransform);
use Storable;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::Scheduler - Schedule messages, repeated and singletons

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
    my $dynamic_schedule = $state->{dynamic_schedule};
    if($message->{dynamic_config}) {
        mtransform($dynamic_schedule, $message->{dynamic_config});
    }
}

sub _tick {
    my $self = shift;
    my $config = $self->{config};
    my $state = $self->{state};
    my $tick = $state->{tick};
    my $schedule = $config->{schedule};
    my $scheduler_sends = $state->{scheduler_sends};
    my $dynamic_schedule = $state->{dynamic_schedule};
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 1;

        #so we should probably merge dynamic_schedule into
        #schedule here.
        my $merged_schedule = {};
        mtransform($merged_schedule, $schedule);
        mtransform($merged_schedule, $dynamic_schedule);
        my $ts = time;
        my @scheduled_keys = keys %$merged_schedule;
        foreach my $scheduled_key (@scheduled_keys) {
            my $scheduled_info = $merged_schedule->{$scheduled_key};
            if($scheduled_info->{runAt}) {
                if($scheduled_info->{runAt} < $ts) {
                    my $message = Storable::dclone($scheduled_info);
                    $message->{scheduler_scheduled_key} = $scheduled_key;
                    $self->emit($message);
                    delete $dynamic_schedule->{$scheduled_key};
                    next;
                }
            }
            #assuming $scheduled_info->{recur} at this point
            my $recur = $scheduled_info->{recur};
            next unless defined $recur;
            $scheduler_sends->{$scheduled_key} = {
                scheduler_create_ts => time,
                scheduler_send_ts => 0,
                scheduler_send_count => 1,
            } unless $scheduler_sends->{$scheduled_key};
            my $scheduler_send_ts = $scheduler_sends->{$scheduled_key}->{scheduler_send_ts};
            if($ts > $scheduler_send_ts + $recur) {
                #send a message
                #what message?
                #start with what's in the schedule, which should at this
                #point contain stuff merged in from $state->{dynamic_schedule}
                #Then merge in $scheduler_sends->{$scheduled_key}
                my $message = Storable::dclone($scheduled_info);
                mtransform($message, $scheduler_sends->{$scheduled_key});
                $message->{scheduler_scheduled_key} = $scheduled_key;
                $self->emit($message);

                $scheduler_sends->{$scheduled_key}->{scheduler_send_count}++;
                $scheduler_sends->{$scheduled_key}->{scheduler_send_ts} = $ts;
            }
        }
    };
    alarm 0;
    if($@) {
        $self->error("_tick failure: $@");
    }
    #this has to happen no matter what
    $state->{tick} = time;
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    my $state = $self->{state};
    if(not $state->{start_tick}) {
        $state->{start_tick} = time;
        $state->{tick} = time;
    }
    $config->{schedule} = {} unless $config->{schedule};
    $state->{scheduler_sends} = {} unless $state->{scheduler_sends};
    $state->{dynamic_schedule} = {} unless $state->{dynamic_schedule};
    $self->named_recur(
        recur_name => 'scheduler_tick',
        repeat_interval => 1,
        work => sub {
            $self->_tick,
        },
    );
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'absolultely required';
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-Scheduler/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::Scheduler


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-Scheduler/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-Scheduler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-Scheduler>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::Scheduler>

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

1; # End of App::MultiModule::Tasks::Scheduler
