# vim:ts=4:sw=4:et
package AnyEvent::XMPP::Ext::Receipts;
use AnyEvent;
use AnyEvent::XMPP::Ext;
use AnyEvent::XMPP::Util qw/is_bare_jid/;
use AnyEvent::XMPP::Namespaces qw/set_xmpp_ns_alias/;
use Data::Dumper;
use warnings;
use strict;

our @ISA = qw/AnyEvent::XMPP::Ext/;

=head1 NAME

AnyEvent::XMPP::Ext::Receipts - XEP-0184 message receipts

=head1 SYNOPSIS

    use AnyEvent::XMPP::Ext::Disco;
    use AnyEvent::XMPP::Ext::Receipts;

    my $disco = AnyEvent::XMPP::Ext::Disco->new();
    $xmpp->add_extension($disco);

    my $receipts = AnyEvent::XMPP::Ext::Receipts->new(disco => $disco);
    $xmpp->add_extension($receipts);

    $disco->enable_feature($receipts->disco_feature);

=head1 DESCRIPTION

This module adds support for XEP-0184 message receipts.

Message receipts provide a way to verify that messages were received by the
recipient, as long as the recipient's client supports it.

Note that you need to send messages with message receipts to full Jabber IDs
(e.g. jabber@example.com/android3948128), not bare Jabber IDs (e.g.
jabber@example.com).

=head1 METHODS

=over

=cut

# A hash which stores whether a certain presence supports XEP-0184 receipts.
# Entries are added after we actually send a message and entries are purged
# when the presence goes offline or is replaced (since the new presence might
# have a different feature set while keeping the same jid).
my %supports_receipts = ();

# A hash which stores timers by message id. When a message is acknowledged, the
# corresponding timer is deleted.
my %timers = ();

=item B<new (%args)>

Creates a new receipts handle.

The following keys can be specified:

=over

=item B<disco>

An C<AnyEvent::XMPP::Ext::Disco> object so that it can be figured out whether
the recipient supports message receipts (via service discovery).

This is required.

=item B<debug>

If you pass a value that evaluates to true, debug messages will be printed to
STDOUT.

=item B<auto_resend>

Amount of time in seconds after which messages will be re-sent when no receipt
was received. Of course messages will only be re-sent if the recipient is known
to support message receipts.

Defaults to 30 (seconds).

Set to 0 to disable automatic re-sending.

=back

Here is an example with all keys set:

    my $receipts = AnyEvent::XMPP::Ext::Receipts->new(
        disco => $disco,
        auto_resend => 30,
        debug => 1,
    );

=cut
sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless { @_ }, $class;
    die "You did not pass an AnyEvent::XMPP::Ext::Disco object as 'disco', see SYNOPSIS"
        unless defined($self->{disco});
    $self->{debug} //= 0;
    # Re-send messages after unacknowledged for 30 seconds.
    $self->{auto_resend} //= 30;
    $self->init;
    $self
}

sub init {
    my ($self) = @_;

    set_xmpp_ns_alias(receipts => 'urn:xmpp:receipts');

    $self->reg_cb(
        ext_before_message_xml => sub {
            my ($self, $con, $node) = @_;

            # Figure out if this is a receive receipt (XEP-0184), such a message
            # looks like this:
            #  <message from="recipient@jabber.ccc.de/androidDc9226M8"
            #   id="CA597-36"
            #   to="me@jabber.ccc.de/18327446281349735808246801">
            #    <received id="foobar23" xmlns="urn:xmpp:receipts"/>
            #  </message>
            my ($receipt) = $node->find_all ([qw/receipts received/]);
            if (defined($receipt)) {
                my $id = $receipt->attr('id');
                print "(xep0184) message $id acknowledged\n" if $self->{debug};
                delete $timers{$id};
                # If the recipient acknowledged our message, he *obviously*
                # supports receipts.
                $supports_receipts{$node->attr('from')} = 1;
                $self->stop_event;
            }

            # Figure out if this is a message which requests a receipt, such as
            # <message from="me@jabber.ccc.de/Psi+" id="aae0a" to="recipient@jabber.ccc.de/presence" type="chat" xml:lang="en">
            #   <body>Did you get this?</body>
            #   <request xmlns="urn:xmpp:receipts"/>
            # </message>
            my ($request) = $node->find_all ([qw/receipts request/]);
            if (defined($request)) {
                my $id = $node->attr('id');
                print "(xep0184) sending receipt for $id\n" if $self->{debug};

                # A receipt looks like this:
                # <message from="recipient@jabber.ccc.de/presence" to="me@jabber.ccc.de/Psi+">
                # <received xmlns="urn:xmpp:receipts" id="aae0a"/>
                # </message>
                $con->send_message(
                    $node->attr('from'),
                    $node->attr('type'),
                    # Add a receipt request tag to the message, like this:
                    # <received xmlns='urn:xmpp:receipts' id="aae0a"/>
                    sub {
                        my $w = shift;
                        $w->addPrefix('urn:xmpp:receipts', '');
                        $w->startTag(['urn:xmpp:receipts', 'received'],
                            id => $id);
                        $w->endTag;
                    },
                    _is_receipt => 1);
            }
        },

        ext_before_send_message_hook => sub {
            my ($self, $con, $id, $to, $type, $attrs, $create_cb) = @_;

            # We can only handle full jids as per XEP-0184 5.1:
            # "If the sender knows only the recipient's bare JID, it cannot
            # cannot determine [...] whether the intended recipient supports
            # the Message Delivery Receipts protoocl. [...] the sender MUST NOT
            # depend on receiving an ack message in reply."
            # If we can’t rely on ack messages, receipts are useless.
            return if is_bare_jid($to);

            # If we have already figured out that the recipient does not
            # support message receipts, sending them (and especially waiting
            # for acknowledge) is pointless.
            return if exists($supports_receipts{$to}) && !$supports_receipts{$to};

            # If this is a message receipt (sent by us), do not add a receipt
            # request, that might lead to an endless loop.
            if ($attrs->{_is_receipt}) {
                # XXX: The need to check a special attribute and delete it here
                # is ugly, but the only way the API provides, as far as I can
                # tell. Patches welcome.
                delete $attrs->{_is_receipt};
                return;
            }

            # Add a receipt request tag to the message, like this:
            # <request xmlns='urn:xmpp:receipts'/>
            push @$create_cb, sub {
                my $w = shift;
                $w->addPrefix('urn:xmpp:receipts', '');
                $w->startTag(['urn:xmpp:receipts', 'request']);
                $w->endTag;
            };

            if ($self->{auto_resend} > 0) {
                print "(xep0184) expecting reply within " . $self->{auto_resend} . "s\n" if $self->{debug};
                # This timer will be deleted when the recipient acknowledges the
                # message. Otherwise, it re-sends the message.
                $timers{$id} = AnyEvent->timer(
                    after => $self->{auto_resend},
                    cb => sub {
                        print "(xep0184) timeout for id $id\n" if $self->{debug};
                        if (!$con->is_connected) {
                            print "(xep0184) skipping re-send: jabber connection offline\n" if $self->{debug};
                            return;
                        }
                        if (!exists($supports_receipts{$to}) || !$supports_receipts{$to}) {
                            # If we don’t know whether the recipient supports
                            # message receipts (and we should by now, since we
                            # start a discovery request when sending the message),
                            # we don’t re-send. Better safe than duplicate msgs :).
                            print "(xep0184) not re-sending, no receipts support\n" if $self->{debug};
                            return;
                        }
                        print "(xep0184) re-sending message $id to $to\n" if $self->{debug};
                        $con->send_message($to, $type, undef, %$attrs);
                    });
            }

            # If we don’t know yet whether the recipient supports message
            # receipts, let’s send a discovery request.
            if (!exists($supports_receipts{$to})) {
                $self->{disco}->request_info($con, $to, undef, sub {
                    my ($disco, $items, $error) = @_;
                    if ($error) {
                        # We can’t figure out whether the recipient supports
                        # receipts, most likely due to a timeout to our
                        # request. We will retry the next time a message is
                        # sent anyways, so do nothing.
                        print "(xep0184) error discovering features: " . $error->string . "\n" if $self->{debug};
                        return;
                    }

                    $supports_receipts{$to} = exists($items->features()->{'urn:xmpp:receipts'});
                    print "(xep0184) cache: $to = " . $supports_receipts{$to} . "\n" if $self->{debug};
                });
            }
        },

        ext_before_presence_xml => sub {
            my ($self, $con, $node) = @_;

            if (($node->attr('type') // '') eq 'unavailable') {
                my $jid = $node->attr('from');
                print "(xep0184) $jid is offline, invalidating cache\n" if $self->{debug};
                delete $supports_receipts{$jid};
            }
        },
    );
}

sub disco_feature {
    'urn:xmpp:receipts';
}

=back

=head1 AUTHOR

Michael Stapelberg, C<< <michael at stapelberg.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Michael Stapelberg

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
