package DJabberd::Plugin::PrivateStorage;
use strict;
use base 'DJabberd::Plugin';
use warnings;

our $logger = DJabberd::Log->get_logger();

use vars qw($VERSION);
$VERSION = '0.60';

=head2 register($self, $vhost)

Register the vhost with the module.

=cut

sub register {
    my ($self, $vhost) = @_;
    my $private_cb = sub {
        my ($vh, $cb, $iq) = @_;
        unless ($iq->isa("DJabberd::IQ")) {
            $cb->decline;
            return;
        }
        if(my $to = $iq->to_jid) {
            unless ($vh->handles_jid($to)) {
                $cb->decline;
                return;
            }
        }
        if ($iq->signature eq 'get-{jabber:iq:private}query') {
            $self->_get_privatestorage($vh, $iq);
            $cb->stop_chain;
            return;
        } elsif ($iq->signature eq 'set-{jabber:iq:private}query') {
            $self->_set_privatestorage($vh, $iq);
            $cb->stop_chain;
            return;
        }
        $cb->decline;
    };
    $vhost->register_hook("switch_incoming_client",$private_cb);
    $vhost->register_hook("switch_incoming_server",$private_cb);
    # should be done ?
    #$vhost->add_feature("vcard-temp");

}

sub _get_privatestorage {
    my ($self, $vhost, $iq) = @_;
    my $user  = $iq->connection->bound_jid->as_bare_string;
    my $content = $iq->first_element()->first_element();; 
    my $element = $content->element();
    $logger->info("Get private storage for user : $user, $element ");
    my $result = $self->load_privatestorage($user, $element);
    if (defined $result and $result) {
        $iq->send_reply('result', qq(<query xmlns="jabber:iq:private">) 
                                  . $result 
                                  . qq(</query>) );
    } else {
        #
        #<iq to='brad@localhost/Gajim' type='result' id='237'>
        #   this is $iq->first_element()
        #   <query xmlns='jabber:iq:private'>
        #   <storage xmlns='storage:rosternotes'/>
        #   </query>
        #</iq>
        $iq->send_reply('result', $iq->first_element()->as_xml());
    }
}

sub _set_privatestorage {
    my ($self, $vhost, $iq) = @_;

    my $user  = $iq->connection->bound_jid->as_bare_string;
    my $content = $iq->first_element()->first_element();; 
    my $element = $content->element();
    $logger->info("Set private storage for user '$user', on $element");
    if (! $self->store_privatestorage( $user,  $element, $content)) {
        $iq->make_error_response('501',"cancel", "feature-not-implemented")->deliver($vhost);
    } else {
        $iq->make_response()->deliver($vhost);
    }
}

=head2 store_privatestorage($self, $user,  $element, $content)

Store $content for $element and $user in the storage module.

=cut

sub store_privatestorage {
    return undef;
}

=head2 load_privatestorage($self, $user,  $element, )

Return the $element for $user from the storage module.

=cut

sub load_privatestorage {
    return undef;
}

1;


__END__

=head1 NAME

DJabberd::Plugin::PrivateStorage - implement private storage, as described in XEP-0049

=head1 DESCRIPTION

This is the base class implementing the logic of XEP-0049, Private storage, for 
DJabberd. Derived only need to implement a storage backend.

=head1 COPYRIGHT

This module is Copyright (c) 2006 Michael Scherer
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 AUTHORS

Michael Scherer <misc@zarb.org>
