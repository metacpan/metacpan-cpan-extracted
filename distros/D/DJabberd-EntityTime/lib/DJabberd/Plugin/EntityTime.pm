package DJabberd::Plugin::EntityTime;

use warnings;
use strict;
use base 'DJabberd::Plugin';

use POSIX qw(strftime);

our $logger = DJabberd::Log->get_logger();

=head1 NAME

DJabberd::EntityTime - Implements XEP-0090 and XEP-0202

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Implements XEP-0090 and XEP-0202

    <Vhost mydomain.com>
	<Plugin DJabberd::Plugin::EntityTime />
    </VHost>

=cut

=head2 register($self, $vhost)

Register the vhost with the module.

=cut

sub register {
    my ($self,$vhost) = @_;
    my $private_cb = sub {
	my ($vh, $cb, $iq) = @_;
	unless ($iq->isa("DJabberd::IQ") and defined $iq->to) {
	    $cb->decline;
	    return;
	}
	unless ($iq->to eq $vhost->{server_name}) {
	    $cb->decline;
	    return;
	}
	if ($iq->signature eq 'get-{jabber:iq:time}query') {
	    $self->_get_time90($vh, $iq);
	    $cb->stop_chain;
	    return;
	} elsif ($iq->signature eq 'get-{urn:xmpp:time}time') {
	    $self->_get_time202($vh, $iq);
	    $cb->stop_chain;
	    return;
	}
	$cb->decline;
    };
    $vhost->register_hook("switch_incoming_client",$private_cb);
    $vhost->register_hook("switch_incoming_server",$private_cb);
    $vhost->add_feature("jabber:iq:time");
    $vhost->add_feature("urn:xmpp:time");
}

sub _get_time90 {
    my ($self, $vh, $iq) = @_;
    $logger->info('Getting time from : '.$iq->from_jid);
    $iq->send_reply('result',qq(<query xmlns="jabber:iq:time">)
	.'<utc>'.strftime("%Y%m%dT%H:%M:%S",gmtime).'</utc>'
	.'<display>'.gmtime().'</display>'
	.'<tz>'.strftime("%Z",gmtime).'</tz>'
	.qq(</query>) );
}

sub _get_time202 {
    my ($self, $vh, $iq) = @_;
    $logger->info('Getting time from : '.$iq->from_jid);
    my $zone = strftime("%z",gmtime);
    $zone =~ s/(\d\d)(\d\d)$/$1:$2/;
    $iq->send_reply('result',qq(<time xmlns="urn:xmpp:time">)
	.'<tzo>'.$zone.'</tzo>'
	.'<utc>'.strftime("%Y%m%dT%H:%M:%S",gmtime).'</utc>'
	.qq(</time>) );
}

=head1 AUTHOR

Edward Rudd, C<< <urkle at outoforder.cc> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Edward Rudd, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of DJabberd::Plugin::EntityTime
