package DJabberd::Plugin::Ping;

use warnings;
use strict;
use base 'DJabberd::Plugin';
our $logger = DJabberd::Log->get_logger();
use DJabberd;

=head1 NAME

DJabberd::Plugin::Ping - Add support for "XEP 0199, Xmpp Ping" to DJabberd.

=head1 VERSION

Version 0.46

=cut
use vars qw($VERSION);
$VERSION = '0.46';

=head1 SYNOPSIS

 <Vhost example.com>
     ...
         <Plugin DJabberd::Plugin::Ping />
     ...
 </VHost>

=cut


=head2 register($self, $vhost)

Register the vhost with the module.

=cut

sub register {
    my ($self, $vhost) = @_;
    my $private_cb = sub {
        my ($vh, $cb, $iq) = @_;
        unless ($iq->isa('DJabberd::IQ')) {
            $cb->decline;
            return;
        }
        unless ( ! $iq->to || $iq->to eq $vhost->{server_name}) {
            $cb->decline;
            return;
        }
        
        if ($iq->signature eq 'get-{urn:xmpp:ping}ping') {
            $self->_get_ping($vh, $iq);
            $cb->stop_chain;
            return;
        }
        $cb->decline;
    };
    $vhost->register_hook('switch_incoming_client',$private_cb);
    $vhost->register_hook('switch_incoming_server',$private_cb);
    # for version 0.3 of the spec 
    # http://mail.jabber.org/pipermail/standards/2006-November/013207.html
    $vhost->add_feature('urn:xmpp:ping');

}

sub _get_ping {
    my ($self, $vhost, $iq) = @_;
    
    $logger->info('Get ping from : ' . $iq->from_jid);
    $iq->send_result();
}

=head1 AUTHOR

Michael Scherer, C<< <misc@zarb.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-djabberd-plugin-ping@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DJabberd-Plugin-Ping>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Michael Scherer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
