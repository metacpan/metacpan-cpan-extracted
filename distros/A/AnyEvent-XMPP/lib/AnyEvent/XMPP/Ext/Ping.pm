package AnyEvent::XMPP::Ext::Ping;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/simxml/;
use AnyEvent::XMPP::Ext;
use strict;

our @ISA = qw/AnyEvent::XMPP::Ext/;

=head1 NAME

AnyEvent::XMPP::Ext::Ping - Implementation of XMPP Ping XEP-0199

=head1 SYNOPSIS

   use AnyEvent::XMPP::Ext::Ping;

   my $con = AnyEvent::XMPP::IM::Connection->new (...);
   $con->add_extension (my $ping = AnyEvent::XMPP::Ext::Ping->new);

   # this enables auto-timeout of a connection if it didn't answer
   # within 120 seconds to a ping with a reply
   $ping->enable_timeout ($con, 120);

   my $cl = AnyEvent::XMPP::Client->new (...);
   $cl->add_extension (my $ping = AnyEvent::XMPP::Ext::Ping->new);

   # this enables auto-timeout of newly created connections
   $ping->auto_timeout (120);

   $ping->ping ($con, 'ping_dest@server.tld', sub {
      my ($time, $error) = @_;
      if ($error) {
         # we got an error
      }
      # $time is a float (seconds) of the rtt if you got Time::HiRes
   });

=head1 DESCRIPTION

This extension implements XEP-0199: XMPP Ping.
It allows you to define a automatic ping timeouter that will disconnect
dead connections (which didn't reply to a ping after N seconds). See also
the documentation of the C<enable_timeout> method below.

It also allows you to send pings to any XMPP entity you like and
will measure the time it took if you got L<Time::HiRes>.

=head1 METHODS

=over 4

=item B<new (%args)>

Creates a new ping handle.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init;
   $self
}

=item B<auto_timeout ($timeout)>

This method enables automatic connection timeout of
new connections. It calls C<enable_timeout> (see below)
for every new connection that was connected and emitted
a C<stream_ready> event.

This is useful if you want connections that have this extension
automatically timeouted. In particular this is useful with modules
like L<AnyEvent::XMPP::Client> (see also L<SYNOPSIS> above).

=cut

sub auto_timeout {
   my ($self, $timeout) = @_;

   $self->{autotimeout} = $timeout;

   return if defined $self->{cb_id2};

   $self->{cb_id2} =
      $self->reg_cb (
         stream_ready => sub {
            my ($self, $con) = @_;
            $self->enable_timeout ($con, \$self->{autotimeout});
         },
         disconnect => sub {
            my ($self, $con) = @_;
            $self->disable_timeout ($con);
         }
      );
}

=item B<enable_timeout ($con, $timeout)>

This enables a periodical ping on the connection C<$con>.
C<$timeout> must be the seconds that the ping intervals last.

If the server which is connected via C<$con> didn't respond within C<$timeout>
seconds the connection C<$con> will be disconnected.

Please note that there already is a basic timeout mechanism
for dead TCP connections in L<AnyEvent::XMPP::Connection>, see also
the C<whitespace_ping_interval> configuration variable for a connection
there. It then will depend on TCP timeouts to disconnect the connection.

Use C<enable_timeout> and C<auto_timeout> only if you really feel
like you need an explicit timeout for your connections.

=cut

sub enable_timeout {
   my ($self, $con, $timeout) = @_;
   my $rt = $timeout;
   unless (ref $timeout) {
      $rt = \$timeout;
   }
   $self->_start_cust_timeout ($con, $rt);
}

sub disable_timeout {
   my ($self, $con) = @_;
   delete $self->{cust_timeouts}->{$con};
}

sub _start_cust_timeout {
   my ($self, $con, $rtimeout) = @_;
   return unless $con->is_connected;

   $self->{cust_timeouts}->{$con} =
      AnyEvent->timer (after => $$rtimeout, cb => sub {
         delete $self->{cust_timeouts}->{$con};
         return unless $con->is_connected;

         $self->ping ($con, undef, sub {
            my ($t, $e) = @_;

            if (defined ($e) && $e->condition eq 'client-timeout') {
               $con->disconnect ("exceeded ping timeout of $$rtimeout seconds");
            } else {
               $self->_start_cust_timeout ($con, $rtimeout)
            }
         }, $$rtimeout);
      });
}

sub init {
   my ($self) = @_;

   if (eval "require Time::HiRes") {
      $self->{has_time_hires} = 1;
   }

   $self->{cb_id} = $self->reg_cb (
      iq_get_request_xml => sub {
         my ($self, $con, $node, $handled) = @_;

         if ($self->handle_ping ($con, $node)) {
            $$handled = 1;
         }
      }
   );
}

sub disco_feature { xmpp_ns ('ping') }

sub DESTROY {
   my ($self) = @_;
   $self->unreg_cb ($self->{cb_id});
   $self->unreg_cb ($self->{cb_id2}) if defined $self->{cb_id2};
}

sub handle_ping {
   my ($self, $con, $node) = @_;

   if (my ($q) = $node->find_all ([qw/ping ping/])) {
      unless ($self->{ignore_pings}) {
         $con->reply_iq_result ($node);
      }
      return 1;
   }

   0;
}

=item B<ping ($con, $dest, $cb, $timeout)>

This method sends a ping request to C<$dest> via the L<AnyEvent::XMPP::Connection>
in C<$con>. If C<$dest> is undefined the ping will be sent to the connected
server.  C<$cb> will be called when either the ping timeouts, an error occurs
or the ping result was received. C<$timeout> is an optional timeout for the
ping request, if C<$timeout> is not given the default IQ timeout for the
connection is the relevant timeout.

The first argument to C<$cb> will be the seconds of the round trip time for
that request (If you have L<Time::HiRes>).  If you don't have L<Time::HiRes>
installed the first argument will be undef.

The second argument to C<$cb> will be either undef if no error occured or
a L<AnyEvent::XMPP::Error::IQ> error object.

=cut

sub ping {
   my ($self, $con, $jid, $cb, $timeout) = @_;

   my $time = 0;
   if ($self->{has_time_hires}) {
      $time = [Time::HiRes::gettimeofday ()];
   }

   $con->send_iq (
      get => { defns => ping => node => { name => 'ping' } },
      sub {
         my ($n, $e) = @_;

         my $elap = 0;
         if ($self->{has_time_hires}) {
            $elap = Time::HiRes::tv_interval ($time, [Time::HiRes::gettimeofday ()]);
         }

         $cb->($elap, $e);
      },
      (defined $jid     ? (to => $jid)          : ()),
      (defined $timeout ? (timeout => $timeout) : ()),
   );
}

=item B<ignore_pings ($bool)>

This method is mostly for testing, it tells this extension
to ignore all ping requests and will prevent any response from
being sent.

=cut

sub ignore_pings {
   my ($self, $enable) = @_;
   $self->{ignore_pings} = $enable;
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
