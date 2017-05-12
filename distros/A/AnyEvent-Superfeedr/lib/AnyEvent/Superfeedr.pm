package AnyEvent::Superfeedr;

use strict;
use warnings;
use 5.008_001;

our $VERSION = '0.04';
use Carp;

use AnyEvent;
use AnyEvent::Superfeedr::Notification;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Superfeedr;
use AnyEvent::XMPP::Ext::Pubsub;
use XML::Atom::Entry;
use Scalar::Util();
use URI::Escape();

our $SERVICE = 'firehoser.superfeedr.com';

use constant SUBSCRIBE_CHUNK_SIZE => 30;

# TODO:
# debug
# tests? worthwhile?
#
# Also, maybe more direct callbacks for sub/unsub

sub new {
    my $class = shift;
    my %param = @_;

    my %filtered;
    for ( qw{ jid password debug
              on_notification on_connect on_disconnect on_error }) {
        $filtered{$_} = delete $param{$_};
    }
    croak "Unknown option(s): " . join ", ", keys %param if keys %param;

    my $superfeedr = bless {
        debug    => $filtered{debug} || 0,
        jid      => $filtered{jid},
        password => $filtered{password},
    }, ref $class || $class;

    ## can be passed to connect() too
    $superfeedr->{on_connect} = $filtered{on_connect}
        if $filtered{on_connect};

    my $on_error = $filtered{on_error} || sub {
        my ($cl, $acc, $err) = @_;
        if (Scalar::Util::blessed($err)) {
            if ($err->isa('AnyEvent::XMPP::Error')) {
                $err = $err->string;
            }
        }
        warn "Error: " . $err;
    };

    my $cl   = AnyEvent::XMPP::Client->new(
        debug => $superfeedr->{debug},
    );
    my $pass = $superfeedr->{password};
    my $jid  = $superfeedr->{jid}
        or croak "You need to specify your jid";

    $cl->add_account($jid, $pass, undef, undef, {
        dont_retrieve_roster => 1,
    });
    $cl->add_extension(my $ps = AnyEvent::XMPP::Ext::Superfeedr->new);
    $superfeedr->{xmpp_pubsub} = $ps;

    $cl->reg_cb(
        error => $on_error,
        connected => sub {
            $superfeedr->{connected} = 1;
            $superfeedr->{on_connect}->($superfeedr)
                if $superfeedr->{on_connect};
        },
        disconnect => sub {
            $superfeedr->{connected} = 0;
            (   $filtered{on_disconnect}
             || sub { warn "Got disconnected from $_[2]:$_[3], $_[4]" }
            )->($superfeedr, @_);
        },
        connect_error => sub {
            my ($cl, $account, $reason) = @_;
            my $jid = $account->bare_jid;
            $on_error->($cl, $account, "connection error for $jid: $reason");
        },
    );
    if (my $on_notification = $filtered{on_notification} ) {
        $ps->reg_cb(
            superfeedr_notification => sub {
                my $ps = shift;
                my $notification = shift;
                $on_notification->($notification);
            },
        );
    }
    $superfeedr->{xmpp_client} = $cl;
    return $superfeedr;
}

sub connect {
    my $superfeedr = shift;
    my $on_connect = shift;

    my $cl = $superfeedr->{xmpp_client}
        or return;
    if ($cl->{connected}) {
        $superfeedr->event(error => "Already connected");
        return;
    }
    $superfeedr->{on_connect} = $on_connect if $on_connect;
    $cl->start;
}

sub subscribe {
    my $superfeedr = shift;
    $superfeedr->pubsub_method('subscribe_nodes', @_);
}

sub unsubscribe {
    my $superfeedr = shift;
    $superfeedr->pubsub_method('unsubscribe_nodes', @_);
}

sub pubsub_method {
    my $superfeedr = shift;
    my($method, @feed_uris) = @_;
    my $cb = ref $feed_uris[-1] eq 'CODE' ? pop @feed_uris : sub { };

    my $pubsub = $superfeedr->xmpp_pubsub;
    unless ($pubsub) {
        $superfeedr->event(error => "no pubsub extension available");
        return;
    }
    my $con = $superfeedr->xmpp_connection;
    unless ($con) {
        $superfeedr->event(error => "Wait to be connected");
        return;
    }

    my @chunk = splice @feed_uris, 0, SUBSCRIBE_CHUNK_SIZE;

    my $res_cb;

    my $chunk_cb = sub {
        my ($chunk, $res_cb) = @_;
        my @xmpp_uris = map { xmpp_node_uri($_) } @$chunk;
        $pubsub->$method($con, \@xmpp_uris, $res_cb);
    };

    $res_cb = sub {
        my $err = shift;
        if ($err) {
            $superfeedr->event(error => $err);
            undef @chunk;
            undef @feed_uris;
        } else {
            $cb->($_) for @chunk;
            if (@feed_uris) {
                @chunk = splice @feed_uris, 0, SUBSCRIBE_CHUNK_SIZE;
                $chunk_cb->(\@chunk, $res_cb);
            }
            else {
                undef $chunk_cb;
                undef $res_cb;
            }
        }
    };
    $chunk_cb->(\@chunk, $res_cb);
}

sub xmpp_node_uri {
    my $enc_feed = URI::Escape::uri_escape_utf8(shift, "\x00-\x1f\x7f-\xff");
    # work around what I think is a but in AnyEvent::XMPP
    #return "xmpp:$SERVICE?;node=$enc_feed";
    return "xmpp:$SERVICE?sub;node=$enc_feed";
}

sub xmpp_pubsub {
    my $superfeedr = shift;
    return $superfeedr->{xmpp_pubsub};
}

sub xmpp_connection {
    my $superfeedr = shift;
    my $con = $superfeedr->{xmpp_connection};
    return $con if $con;

    my $client = $superfeedr->{xmpp_client} or return;
    my $jid = $superfeedr->{jid};
    my $account = $client->get_account($jid) or return;
    $con = $account->connection;
    $superfeedr->{xmpp_connection} = $con;
    return $con;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::Superfeedr - XMPP interface to Superfeedr service.

=head1 SYNOPSIS

  use AnyEvent::Superfeedr;

  my $callback = sub {
      my AnyEvent::Superfeedr::Notification $notification = shift;
      my $feed_uri    = $notification->feed_uri;
      my $http_status = $notification->http_status;
      my $next_fetch  = $notification->next_fetch;
      printf "status %s for %s. next: %s\n",
              $http_status, $feed_uri, $next_fetch;
      for my XML::Atom::Entry $entry ($notification->entries) {
          printf "Got: %s\n" $entry->title;
      }
  };

  my $superfeedr = AnyEvent::Superfeedr->new(
      jid => $jid,
      password => $password
      on_notification => $callback,
  );
  $superfeedr->connect;
  AnyEvent->condvar->recv;

  # Subsribe upon connection
  my $superfeedr = AnyEvent::Superfeedr->new(
      jid => $jid,
      password => $password,
  );
  $superfeedr->connect(sub { $superfeedr->subscribe($feed_uri) });

  # Periodically fetch new URLs from database and subscribe
  my $timer = AnyEvent->timer(
      after => 5,
      interval => 5 * 60,
      cb => sub {
          my @new_feeds = get_new_feeds_from_database() or return;
          $superfeedr->subscribe(@new_feeds);
      },
  );

  $end->recv;

=head1 DESCRIPTION

WARNING: the interface is likely to change in the future.

Allows you to subscribe to feeds and get notified real-time about new
content.

This is a first version of the api, and probably only covers specific
architectural needs.

=head1 EXAMPLES

see in the eg/ directory of the distribution.

=head1 AUTHOR

Yann Kerherve E<lt>yannk@cpan.orgE<gt>

=head1 CONTRIBUTORS

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::XMPP> L<AnyEvent> L<http://superfeedr.com>

=cut
