package App::MultiModule::Tasks::SMTPGateway;
$App::MultiModule::Tasks::SMTPGateway::VERSION = '1.162230';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Message::Transform qw(mtransform);
use Storable;
use Email::Stuffer;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::SMTPGateway - Task to allow message driven e-mail

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
    my $state = $self->{state};
    for ('smtp_to','smtp_from','smtp_subject','smtp_body') {
        if(not $message->{$_}) {
            $self->error("App::MultiModule::Tasks::SMTPGateway::message: submitted message requires field '$_'");
            return undef;
        }
    }
    my $deliver_ttl = $config->{deliver_ttl} || 5;
    $message->{'_smtp_gateway_ttl'} = $deliver_ttl
        unless $message->{'_smtp_gateway_ttl'};
    push @{$state->{messages}}, $message;
}

sub _deliver_message {
    my $self = shift;
    my $config = $self->{config};
    my $message = shift;
    my @to;
    if(ref $message->{smtp_to} and ref $message->{smtp_to} eq 'ARRAY') {
        @to = @{$message->{smtp_to}};
    } elsif(not ref $message->{smtp_to}) {
        $to[0] = $message->{smtp_to};
    }
    my @errs;
    foreach my $to (@to) {
        eval {
            my $send = Email::Stuffer->from($message->{smtp_from})
                ->to($to)
                ->subject($message->{smtp_subject})
                ->text_body($message->{smtp_body});
            $send->transport(@{$message->{smtp_transport}})
                if $message->{smtp_transport};
            $send->send_or_die;
        };
        push @errs, $@ if $@;
    }
    if(scalar @errs) {
        my $errs = join "\n", @errs;
        die $errs;
    }
}

sub _tick {
    my $self = shift;
    my $config = $self->{config};
    my $tick_timeout = $config->{tick_timeout} || 5;
    my $state = $self->{state};
    my $message;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm $tick_timeout;
        while($message = shift(@{$state->{messages}})) {
            $message->{'_smtp_gateway_ttl'}--;
            if(not $message->{'_smtp_gateway_ttl'}) {
                $self->error('App::MultiModule::Tasks::SMTPGateway::_tick: message dropped because after multiple delivery attempts', message => $message);
                next;
            }
            die 'configured to test exceptions'
                if $config->{test_exceptions};
            $self->_deliver_message($message);
        }
        undef $message;
    };
    alarm 0;
    if($@) {
        $self->error("App::MultiModule::Tasks::SMTPGateway::_tick failed: $@",
            message => $message);
    }
    unshift @{$state->{messages}}, $message if $message;
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    my $state = $self->{state};
    $state->{messages} = [] unless $state->{messages};
    $self->named_recur(
        recur_name => 'SMTPGateway_tick',
        repeat_interval => 1,
        work => sub {
            $self->_tick,
        },
    );
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'yes';
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-SMTPGateway/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::SMTPGateway


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-SMTPGateway/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-SMTPGateway>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-SMTPGateway>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::SMTPGateway>

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

1; # End of App::MultiModule::Tasks::SMTPGateway
