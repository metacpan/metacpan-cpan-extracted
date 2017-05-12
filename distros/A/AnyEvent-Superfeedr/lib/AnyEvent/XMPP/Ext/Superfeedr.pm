package AnyEvent::XMPP::Ext::Superfeedr;
use strict;
use warnings;

use AnyEvent::Superfeedr::Notification;
use base qw/AnyEvent::XMPP::Ext::Pubsub/;

use AnyEvent::XMPP::Util qw/simxml split_uri/;

use constant NS => 'http://superfeedr.com/xmpp-pubsub-ext';

=pod

Fires up Pubsub event's plus 2 new events:

=over 4

=item superfeedr_status( $status_hash )

A hash with the content of status

=item superfeedr_notification( $notification

A L<AnyEvent::Superfeedr::Notification> object.

=back

=cut

sub handle_incoming_pubsub_event {
    my ($self, $node) = @_;

    my (@items, $status_node);
    my ($code, $next_fetch, $title, $feed_uri);

    if ( ($status_node) = $node->find_all([NS, 'status'])) {
        my ($http_node)       = $status_node->find_all([NS, 'http' ]);
        my ($next_fetch_node) = $status_node->find_all([NS, 'next_fetch' ]);
        my ($title_node)      = $status_node->find_all([NS, 'title' ]);

        $code       = $http_node       ? $http_node->attr('code') : undef;
        $next_fetch = $next_fetch_node ? $next_fetch_node->text   : undef;
        $title      = $title_node      ? $title_node->text        : undef;
        $feed_uri   = $status_node->attr('feed');

        my $status = {
            http_status => $code,
            next_fecth  => $next_fetch,
            title       => $title,
            feed_uri    => $feed_uri,
        };
        $self->event(superfeedr_status => $status);
    }
    if ( my ($q) = $node->find_all([qw/ pubsub_ev items /]) ) {
        foreach ( $q->find_all([ qw/pubsub item /] )) {
            push @items, $_;
        }
    }
    my $notification = AnyEvent::Superfeedr::Notification->new(
        http_status => $code,
        next_fetch  => $next_fetch,
        title       => $title,
        feed_uri    => $feed_uri,
        items       => [ @items ],
    );
    $self->event(pubsub_recv => @items);
    $self->event(superfeedr_notification => $notification);
}

sub subscribe_nodes {
    my ($self, $con, $uris, $cb) = @_;
    return $self->_pubsub_nodes('subscribe', $con, $uris, $cb);
}

sub unsubscribe_nodes {
    my ($self, $con, $uris, $cb) = @_;
    return $self->_pubsub_nodes('unsubscribe', $con, $uris, $cb);
}

sub _pubsub_nodes {
    my ($self, $method, $con, $uris, $cb) = @_;

    my $jid = $con->jid;

    my @children;
    my $service;
    for (@$uris) {
        ($service, my $node) = split_uri($_);
        push @children, {
            name => $method, attrs => [
                node => $node,
                jid => $jid,
            ],
        };
    }

    $con->send_iq (
        set => sub {
            my ($w) = @_;
            simxml ($w, defns => 'pubsub', node => {
                    name => 'pubsub', childs => \@children,
            });
        },
        sub {
            my ($node, $err) = @_;
            $cb->(defined $err ? $err : ()) if $cb;
        },
        (defined $service ? (to => $service) : ())
    );
}

1;
