package App::MultiModule::Tasks::Heartbeat;
$App::MultiModule::Tasks::Heartbeat::VERSION = '1.161950';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Message::Transform qw(mtransform);
use Message::Match qw(mmatch);
use Storable;
use POSIX ":sys_wait_h";

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::Heartbeat - Detect missing streams or attributes

=cut

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    my $config = $self->{config};
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    my $instances = $self->{state}->{instances};
    while(my($hb_group_name, $hb_group) = each %{$config->{hb_groups}}) {
        #first find any hb_groups that apply to us
        next unless $hb_group->{match};
        next unless mmatch($message, $hb_group->{match});
        next unless $hb_group->{hb_instance};
        mtransform($message, { hb_instance => $hb_group->{hb_instance} });
        my $hb_instance = $message->{hb_instance};
        if(not $hb_instance) {
            $self->error("App::MultiModule::Tasks::Heartbeat::message: no hb_instance set bis \$hb_group_name=$hb_group_name \$hb_group->{hb_instance}=$hb_group->{hb_instance}");
            next;
        }
        $instances->{$hb_group_name} = {} unless $instances->{$hb_group_name};
        if(not $instances->{$hb_group_name}->{$hb_instance}) {
            $instances->{$hb_group_name}->{$hb_instance} = {
                last_emit_ts => 0,
            }
        }
        my $instance = $instances->{$hb_group_name}->{$hb_instance};
        $instance->{message_receive_ts} = time;
        $instance->{last_message} = Storable::dclone($message);
        delete $instance->{last_message}->{'.ipc_transit_meta'};
        #branch to different types of heartbeat config here
        if(     $hb_group->{changing_fields} and
                ref $hb_group->{changing_fields} and
                ref $hb_group->{changing_fields} eq 'ARRAY') {
            #this is the 'changing_fields' type
            $instance->{changed_fields} = {} unless $instance->{changed_fields};

            foreach my $changing_fieldname (@{$hb_group->{changing_fields}}) {
                $instance->{changed_fields}->{$changing_fieldname} = {}
                    unless $instance->{changed_fields}->{$changing_fieldname};
                my $field = $instance->{changed_fields}->{$changing_fieldname};
                next unless defined $message->{$changing_fieldname};
                if(     not defined $field->{last_value} or
                        $field->{last_value} ne $message->{$changing_fieldname}) {
                    $field->{last_change_ts} = time;
                    $field->{last_value} = $message->{$changing_fieldname};
                }
            }
        } #else other types
    }
}

sub _tick {
    my $self = shift;
    my $config = $self->{config};
    my $instances = $self->{state}->{instances};
    my $timeout = $self->{config}->{tick_timeout} || 1;
    my $ts = time;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm $timeout;
        while(my($hb_group_name,$hb_groups) = each %$instances) {
            while(my($hb_instance_name, $instance) = each %$hb_groups) {
                my $group_config = $config->{hb_groups}->{$hb_group_name};
                my $emit_ts_span = $group_config->{emit_ts_span} || 10;
                my $last_emit_ts = $instance->{last_emit_ts};
                next if $ts - $emit_ts_span < $last_emit_ts;
                my $message = $instance->{last_message};
                mtransform($message, $group_config->{transform})
                    if $group_config->{transform};
                $instance->{last_emit_ts} = $ts;
                #now set hearbeat_last_change_ts_span
                $message->{hearbeat_last_change_ts_span} = 0; #default
                while(my($change_field_name, $field) = each %{$instance->{changed_fields}}) {
                    $message->{hearbeat_last_change_ts_span} = $ts - $field->{last_change_ts}
                        if $ts - $field->{last_change_ts} > $message->{hearbeat_last_change_ts_span};
                }
                $self->emit($message);
            }
        }
    };
    if($@) {
        print STDERR "error: $@\n";
        $self->error("App::MultiModule::Tasks::Heartbeat::_tick: general exception: $@");
    }
    alarm 0;
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->{config}->{hb_groups} = {}
        unless $self->{config}->{hb_groups};
    $self->{state}->{instances} = {}
        unless $self->{state}->{instances};
    $self->named_recur(
        recur_name => 'Heartbeat_tick',
        repeat_interval => 1,
        work => sub {
            $self->_tick;
        }
    );
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'certainly';
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-Heartbeat/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::Heartbeat


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-Heartbeat/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-Heartbeat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-Heartbeat>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::Heartbeat>

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

1; # End of App::MultiModule::Tasks::Heartbeat
