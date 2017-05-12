package AnyEvent::XMPP::Connection;
use strict;
use AnyEvent;
use AnyEvent::XMPP::Parser;
use AnyEvent::XMPP::Writer;
use AnyEvent::XMPP::Util qw/split_jid join_jid simxml/;
use AnyEvent::XMPP::SimpleConnection;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Extendable;
use AnyEvent::XMPP::Error;
use Object::Event;
use Digest::SHA qw/sha1_hex/;
use Encode;

our @ISA = qw/AnyEvent::XMPP::SimpleConnection Object::Event AnyEvent::XMPP::Extendable/;

=head1 NAME

AnyEvent::XMPP::Connection - XML stream that implements the XMPP RFC 3920.

=head1 SYNOPSIS

   use AnyEvent::XMPP::Connection;

   my $con =
      AnyEvent::XMPP::Connection->new (
         username => "abc",
         domain => "jabber.org",
         resource => "AnyEvent::XMPP"
      );

   $con->reg_cb (stream_ready => sub { print "XMPP stream ready!\n" });
   $con->connect; # will do non-blocking connect

=head1 DESCRIPTION

This module represents a XMPP stream as described in RFC 3920. You can issue the basic
XMPP XML stanzas with methods like C<send_iq>, C<send_message> and C<send_presence>.

And receive events with the C<reg_cb> event framework from the connection.

If you need instant messaging stuff please take a look at C<AnyEvent::XMPP::IM::Connection>.

=head1 METHODS

=over 4

=item B<new (%args)>

Following arguments can be passed in C<%args>:

=over 4

=item language => $tag

This should be the language of the human readable contents that
will be transmitted over the stream. The default will be 'en'.

Please look in RFC 3066 how C<$tag> should look like.

=item jid => $jid

This can be used to set the settings C<username>, C<domain>
(and optionally C<resource>) from a C<$jid>.

=item username => $username

This is your C<$username> (the userpart in the JID);

Note: You have to take care that the stringprep profile for
nodes can be applied at: C<$username>. Otherwise the server
might signal an error. See L<AnyEvent::XMPP::Util> for utility functions
to check this.

B<NOTE:> This field has no effect if C<jid> is given!

=item domain => $domain

If you didn't provide a C<jid> (see above) you have to set the
C<username> which you want to connect as (see above) and the
C<$domain> to connect to.

B<NOTE:> This field has no effect if C<jid> is given!

=item resource => $resource

If this argument is given C<$resource> will be passed as desired
resource on resource binding.

Note: You have to take care that the stringprep profile for
resources can be applied at: C<$resource>. Otherwise the server
might signal an error. See L<AnyEvent::XMPP::Util> for utility functions
to check this.

=item host => $host

This parameter specifies the hostname where we are going
to connect to. The default for this is the C<domain> of the C<jid>.

B<NOTE:> To disable DNS SRV lookup you need to specify the port B<number>
yourself. See C<port> below.

=item use_host_as_sasl_hostname => $bool

This is a special parameter for people who might want to use GSSAPI SASL
mechanism. It will cause the value of the C<host> parameter (see above) to be
passed to the SASL mechanisms, instead of the C<domain> of the JID.

This flag is provided until support for XEP 0233 is deployed, which
will fix the hostname issue w.r.t. GSSAPI SASL.

=item port => $port

This is optional, the default value for C<$port> is 'xmpp-client=5222', which
will used as C<$service> argument to C<tcp_connect> of L<AnyEvent::Socket>.
B<NOTE:> If you specify the port number here (instead of 'xmpp-client=5222'),
B<no> DNS SRV lookup will be done when connecting.

=item connect_timeout => $timeout

This sets the connection timeout. If the socket connect takes too long
a C<disconnect> event will be generated with an appropriate error message.
If this argument is not given no timeout is installed for the connects.

=item password => $password

This is the password for the C<username> above.

=item disable_ssl => $bool

If C<$bool> is true no SSL will be used.

=item old_style_ssl => $bool

If C<$bool> is true the TLS handshake will be initiated when the TCP
connection was established. This is useful if you have to connect to
an old Jabber server, with old-style SSL connections on port 5223.

But that practice has been discouraged in XMPP, and a TLS handshake is done
after the XML stream has been established. Only use this option if you know
what you are doing.

=item disable_sasl => $bool

If C<$bool> is true SASL will NOT be used to authenticate with the server, even
if it advertises SASL through stream features.  Alternative authentication
methods will be used, such as IQ Auth (XEP-0078) if the server offers it.

=item disable_iq_auth => $bool

This disables the use of IQ Auth (XEP-0078) for authentication, you might want
to exclude it because it's deprecated and insecure. (However, I want to reach a
maximum in compatibility with L<AnyEvent::XMPP> so I'm not disabling this by
default.

See also C<disable_old_jabber_authentication> below.

=item anal_iq_auth => $bool

This enables the anal iq auth mechanism that will first look in the stream
features before trying to start iq authentication. Yes, servers don't always
advertise what they can. I only implemented this option for my test suite.

=item disable_old_jabber_authentication => $bool

If C<$bool> is a true value, then the B<VERY> old style authentication method
with B<VERY> old jabber server won't be used when a <stream> start tag from the server
without version attribute is received.

The B<VERY> old style authentication method is per default enabled to ensure
maximum compatibility with old jabber implementations. The old method works as
follows: When a <stream> start tag is received from the server with no
'version' attribute IQ Auth (XEP-0078) will be initiated to authenticate with
the server.

Please note that the old authentication method will fail if C<disable_iq_auth>
is true.

=item stream_version_override => $version

B<NOTE:> Only use if you B<really> know what you are doing!

This will override the stream version which is sent in the XMPP stream
initiation element. This is currently only used by the tests which
set C<$version> to '0.9' for testing IQ authentication with ejabberd.

=item whitespace_ping_interval => $interval

This will set the whitespace ping interval (in seconds). The default interval
are 60 seconds.  You can disable the whitespace ping by setting C<$interval> to
0.

=back

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self =
      $class->SUPER::new (
         language         => 'en',
         stream_namespace => 'client',
         whitespace_ping_interval => 60,
         @_
      );

   $self->{parser} = new AnyEvent::XMPP::Parser;
   $self->{writer} = AnyEvent::XMPP::Writer->new (
      write_cb     => sub { $self->write_data ($_[0]) },
      send_iq_cb   => sub { my @cb; $self->event (send_iq_hook => (@_, \@cb)); return @cb },
      send_msg_cb  => sub { my @cb; $self->event (send_message_hook => (@_, \@cb)); return @cb },
      send_pres_cb => sub { my @cb; $self->event (send_presence_hook => (@_, \@cb)); return @cb },
   );

   $self->{parser}->set_stanza_cb (sub {
      eval {
         $self->handle_stanza (@_);
      };
      if ($@) {
         $self->event (error =>
            AnyEvent::XMPP::Error::Exception->new (
               exception => $@, context => 'stanza handling'
            )
         );
      }
   });
   $self->{parser}->set_error_cb (sub {
      my ($ex, $data, $type) = @_;

      if ($type eq 'xml') {
         my $pe = AnyEvent::XMPP::Error::Parser->new (exception => $_[0], data => $_[1]);
         $self->event (xml_parser_error => $pe);
         $self->disconnect ("xml error: $_[0], $_[1]");

      } else {
         my $pe = AnyEvent::XMPP::Error->new (
            text => "uncaught exception in stanza handling: $ex"
         );
         $self->event (uncaught_exception_error => $pe);
         $self->disconnect ($pe->string);
      }
   });

   $self->{parser}->set_stream_cb (sub {
      $self->{stream_id} = $_[0]->attr ('id');

      # This is some very bad "hack" for _very_ old jabber
      # servers to work with AnyEvent::XMPP
      if (not defined $_[0]->attr ('version')) {
         $self->start_old_style_authentication
            if (not $self->{disable_iq_auth})
               && (not $self->{disable_old_jabber_authentication})
      }
   });


   $self->{iq_id}              = 1;
   $self->{default_iq_timeout} = 60;

   $self->{disconnect_cb} = sub {
      my ($host, $port, $message) = @_;
      delete $self->{authenticated};
      delete $self->{ssl_enabled};
      $self->event (disconnect => $host, $port, $message);
      $self->{disconnect_cb} = sub {};
      delete $self->{writer};
      $self->{parser}->cleanup;
      delete $self->{parser};
   };

   if ($self->{jid}) {
      my ($user, $host, $res) = split_jid ($self->{jid});
      $self->{username} = $user;
      $self->{domain}   = $host;
      $self->{resource} = $res if defined $res;
   }

   $self->{host} = $self->{domain}    unless defined $self->{host};
   $self->{port} = 'xmpp-client=5222' unless defined $self->{port};

   my $proxy_cb = sub {
      my ($self, $er) = @_;
      $self->event (error => $er);
   };

   $self->reg_cb (
      xml_parser_error => $proxy_cb,
      sasl_error       => $proxy_cb,
      stream_error     => $proxy_cb,
      bind_error       => $proxy_cb,
      iq_auth_error    => $proxy_cb,
      iq_result_cb_exception => sub {
         my ($self, $ex) = @_;
         $self->event (error =>
            AnyEvent::XMPP::Error::Exception->new (
               exception => $ex, context => 'iq result callback execution'
            )
         );
      },
      tls_error => sub {
         my ($self) = @_;
         $self->event (error =>
            AnyEvent::XMPP::Error->new (text => 'tls_error: tls negotiation failed')
         );
      },
      iq_xml => sub { shift @_; $self->handle_iq (@_) }
   );

   if ($self->{whitespace_ping_interval} > 0) {
      $self->reg_cb (
         stream_ready => sub {
            my ($self) = @_;
            $self->_start_whitespace_ping;
            $self->unreg_me;
         },
         disconnect => sub {
            $self->_stop_whitespace_ping;
            $self->unreg_me;
         }
      );
   }

   $self->set_exception_cb (sub {
      my ($ex) = @_;
      $self->event (error =>
         AnyEvent::XMPP::Error::Exception->new (
            exception => $ex, context => 'event callback'
         )
      );
   });

   return $self;
}

=item B<connect ()>

Try to connect (non blocking) to the domain and port passed in C<new>.

The connection is performed non blocking, so this method will just
trigger the connection process. The event C<connect> will be emitted
when the connection was successfully established.

If the connection try was not successful a C<disconnect> event
will be generated with an error message.

NOTE: Please note that you can't reconnect a L<AnyEvent::XMPP::Connection>
object. You need to recreate it if you want to reconnect.

NOTE: The "XML" stream initiation is sent when the connection
was successfully connected.


=cut

sub connect {
   my ($self) = @_;
   $self->SUPER::connect ($self->{host}, $self->{port}, $self->{connect_timeout});
}

sub connected {
   my ($self) = @_;

   if ($self->{old_style_ssl}) {
      $self->enable_ssl;
   }

   $self->init;
   $self->event (connect => $self->{peer_host}, $self->{peer_port});
}

sub send_buffer_empty {
   my ($self) = @_;
   $self->event ('send_buffer_empty');
}

sub handle_data {
   my ($self, $buf) = @_;
   $self->event (debug_recv => $$buf);
   $self->{parser}->feed (substr $$buf, 0, (length $$buf), '');
}

sub debug_wrote_data {
   my ($self, $data) = @_;
   $self->event (debug_send => $data);
}

sub write_data {
   my ($self, $data) = @_;
   $self->event (send_stanza_data => $data);
   $self->SUPER::write_data ($data);
}

sub default_namespace {
   return 'client';
}

sub handle_stanza {
   my ($self, $p, $node) = @_;

   if (not defined $node) { # got stream end
      $self->disconnect ("end of 'XML' stream encountered");
      return;
   }

   my $stop = 0;
   $self->event (recv_stanza_xml => $node, \$stop);
   $stop and return;

   my $def_ns = $self->default_namespace;

   if ($node->eq (stream => 'features')) {
      $self->event (stream_features => $node);
      $self->{features} = $node;
      $self->handle_stream_features ($node);

   } elsif ($node->eq (tls => 'proceed')) {
      $self->enable_ssl;
      $self->{parser}->init;
      $self->{writer}->init;
      $self->{writer}->send_init_stream (
         $self->{language}, $self->{domain}, $self->{stream_namespace}
      );

   } elsif ($node->eq (tls => 'failure')) {
      $self->event ('tls_error');
      $self->disconnect ('TLS failure on TLS negotiation.');

   } elsif ($node->eq (sasl => 'challenge')) {
      $self->handle_sasl_challenge ($node);

   } elsif ($node->eq (sasl => 'success')) {
      $self->handle_sasl_success ($node);

   } elsif ($node->eq (sasl => 'failure')) {
      my $error = AnyEvent::XMPP::Error::SASL->new (node => $node);
      $self->event (sasl_error => $error);
      $self->disconnect ('SASL authentication failure: ' . $error->string);

   } elsif ($node->eq ($def_ns => 'iq')) {
      $self->event (iq_xml => $node);

   } elsif ($node->eq ($def_ns => 'message')) {
      $self->event (message_xml => $node);

   } elsif ($node->eq ($def_ns => 'presence')) {
      $self->event (presence_xml => $node);

   } elsif ($node->eq (stream => 'error')) {
      $self->handle_error ($node);
   }
}

# This method is private

sub init {
   my ($self) = @_;
   $self->{writer}->send_init_stream ($self->{language}, $self->{domain}, $self->{stream_namespace}, $self->{stream_version_override});
}

=item B<is_connected ()>

Returns true if the connection is still connected and stanzas can be
sent.

=cut

sub is_connected {
   my ($self) = @_;
   $self->{authenticated}
}

=item B<set_default_iq_timeout ($seconds)>

This sets the default timeout for IQ requests. If the timeout runs out
the request will be aborted and the callback called with a L<AnyEvent::XMPP::Error::IQ> object
where the C<condition> method returns a special value (see also C<condition> method of L<AnyEvent::XMPP::Error::IQ>).

The default timeout for IQ is 60 seconds.

=cut

sub set_default_iq_timeout {
   my ($self, $sec) = @_;
   $self->{default_iq_timeout} = $sec;
}

=item B<send_iq ($type, $create_cb, $result_cb, %attrs)>

This method sends an IQ XMPP B<request>.

If you want to B<respond> to a IQ request you received via the C<iq_set_request_xml>,
and C<iq_get_request_xml> events you have to use the C<reply_iq_result> or
C<reply_iq_error> methods documented below.

Please take a look at the documentation for C<send_iq> in AnyEvent::XMPP::Writer
about the meaning of C<$type>, C<$create_cb> and C<%attrs> (with the exception
of the 'timeout' key of C<%attrs>, see below).

C<$result_cb> will be called when a result was received or the timeout reached.
The first argument to C<$result_cb> will be a AnyEvent::XMPP::Node instance
containing the IQ result stanza contents.

If the IQ resulted in a stanza error the second argument to C<$result_cb> will
be C<undef> (if the error type was not 'continue') and the third argument will
be a L<AnyEvent::XMPP::Error::IQ> object.

The timeout can be set by C<set_default_iq_timeout> or passed separately
in the C<%attrs> array as the value for the key C<timeout> (timeout in seconds btw.).

This method returns the newly generated id for this iq request.

=cut

sub send_iq {
   my ($self, $type, $create_cb, $result_cb, %attrs) = @_;
   my $id = $self->{iq_id}++;
   $self->{iqs}->{$id} = $result_cb;

   my $timeout = delete $attrs{timeout} || $self->{default_iq_timeout};
   if ($timeout) {
      $self->{iq_timers}->{$id} =
         AnyEvent->timer (after => $timeout, cb => sub {
            delete $self->{iq_timers}->{$id};
            my $cb = delete $self->{iqs}->{$id};
            $cb->(undef, AnyEvent::XMPP::Error::IQ->new)
         });
   }

   $self->{writer}->send_iq ($id, $type, $create_cb, %attrs);
   $id
}

=item B<next_iq_id>

This method returns the next IQ id that will be used.

=cut

sub next_iq_id {
   $_[0]->{iq_id};
}

=item B<reply_iq_result ($req_iq_node, $create_cb, %attrs)>

This method will generate a result reply to the iq request C<AnyEvent::XMPP::Node>
in C<$req_iq_node>.

Please take a look at the documentation for C<send_iq> in L<AnyEvent::XMPP::Writer>
about the meaning C<$create_cb> and C<%attrs>.

Use C<$create_cb> to create the XML for the result.

The type for this iq reply is 'result'.

The C<to> attribute of the reply stanza will be set to the C<from>
attribute of the C<$req_iq_node>. If C<$req_iq_node> had no C<from>
node it won't be set. If you want to overwrite the C<to> field just
pass it via C<%attrs>.

=cut

sub reply_iq_result {
   my ($self, $iqnode, $create_cb, %attrs) = @_;
   
   return $self->_reply_iq(
      $iqnode,
      'result',
      $create_cb,
      %attrs
   );
}

=item B<reply_iq_error ($req_iq_node, $error_type, $error, %attrs)>

This method will generate an error reply to the iq request C<AnyEvent::XMPP::Node>
in C<$req_iq_node>.

C<$error_type> is one of 'cancel', 'continue', 'modify', 'auth' and 'wait'.
C<$error> is one of the defined error conditions described in
C<write_error_tag> method of L<AnyEvent::XMPP::Writer>.

Please take a look at the documentation for C<send_iq> in AnyEvent::XMPP::Writer
about the meaning of C<%attrs>.

The type for this iq reply is 'error'.

The C<to> attribute of the reply stanza will be set to the C<from>
attribute of the C<$req_iq_node>. If C<$req_iq_node> had no C<from>
node it won't be set. If you want to overwrite the C<to> field just
pass it via C<%attrs>.

=cut

sub reply_iq_error {
   my ($self, $iqnode, $errtype, $error, %attrs) = @_;

   return $self->_reply_iq(
      $iqnode,
      'error',
      sub { $self->{writer}->write_error_tag ($iqnode, $errtype, $error) },
      %attrs
   );
}

sub _reply_iq {
   my ($self, $iqnode, $type, $create_cb, %attrs) = @_;

   return $self->{writer}->send_iq (
      $iqnode->attr ('id'), $type, $create_cb,
      (defined $iqnode->attr ('from') ? (to => $iqnode->attr ('from')) : ()),
      (defined $iqnode->attr ('to') ? (from => $iqnode->attr ('to')) : ()),
      %attrs
   );
}

sub handle_iq {
   my ($self, $node) = @_;

   my $type = $node->attr ('type');

   my $id = $node->attr ('id');
   delete $self->{iq_timers}->{$id} if defined $id;

   if ($type eq 'result') {
      if (my $cb = delete $self->{iqs}->{$id}) {
         eval {
            $cb->($node);
         };
         if ($@) { $self->event (iq_result_cb_exception => $@) }
      }

   } elsif ($type eq 'error') {
      if (my $cb = delete $self->{iqs}->{$id}) {

         my $error = AnyEvent::XMPP::Error::IQ->new (node => $node);

         eval {
            $cb->(($error->type eq 'continue' ? $node : undef), $error);
         };
         if ($@) { $self->event (iq_result_cb_exception => $@) }
      }

   } else {
      my $handled = 0;
      $self->event ("iq_${type}_request_xml" => $node, \$handled);
      $handled or $self->reply_iq_error ($node, undef, 'service-unavailable');
   }
}

sub send_sasl_auth {
   my ($self, @mechs) = @_;

   for (qw/username password domain/) {
      die "No '$_' argument given to new, but '$_' is required\n"
         unless defined $self->{$_};
   }

   $self->{writer}->send_sasl_auth (
      [map { $_->text } @mechs],
      $self->{username},
      ($self->{use_host_as_sasl_hostname}
         ? $self->{host}
         : $self->{domain}),
      $self->{password}
   );
}

sub handle_stream_features {
   my ($self, $node) = @_;
   my @bind  = $node->find_all ([qw/bind bind/]);
   my @tls   = $node->find_all ([qw/tls starttls/]);

   # and yet another weird thingie: in XEP-0077 it's said that
   # the register feature MAY be advertised by the server. That means:
   # it MAY not be advertised even if it is available... so we don't
   # care about it...
   # my @reg   = $node->find_all ([qw/register register/]);

   if (not ($self->{disable_ssl}) && not ($self->{ssl_enabled}) && @tls) {
      $self->{writer}->send_starttls;

   } elsif (not $self->{authenticated}) {
      my $continue = 1;
      $self->event (stream_pre_authentication => \$continue);
      if ($continue) {
         $self->authenticate;
      }

   } elsif (@bind) {
      $self->do_rebind ($self->{resource});
   }
}

=item B<authenticate>

This method should be called after the C<stream_pre_authentication> event
was emitted to continue authentication of the stream.

Usually this method only has to be called when you want to register before
you authenticate. See also the documentation of the C<stream_pre_authentication>
event below.

=cut

sub authenticate {
   my ($self) = @_;
   my $node = $self->{features};
   my @mechs = $node->find_all ([qw/sasl mechanisms/], [qw/sasl mechanism/]);

   # Yes, and also iq-auth isn't correctly advertised in the
   # stream features! We all love the depreacted XEP-0078, eh?
   my @iqa = $node->find_all ([qw/iqauth auth/]);

   if (not ($self->{disable_sasl}) && @mechs) {
      $self->send_sasl_auth (@mechs)

   } elsif (not $self->{disable_iq_auth}) {
      if ($self->{anal_iq_auth} && !@iqa) {
         if (@iqa) {
            $self->do_iq_auth;
         } else {
            die "No authentication method left after anal iq auth, neither SASL or IQ auth.\n";
         }
      } else {
         $self->do_iq_auth;
      }

   } else {
      die "No authentication method left, neither SASL or IQ auth.\n";
   }
}

sub handle_sasl_challenge {
   my ($self, $node) = @_;
   $self->{writer}->send_sasl_response ($node->text);
}

sub handle_sasl_success {
   my ($self, $node) = @_;
   $self->{authenticated} = 1;
   $self->{parser}->init;
   $self->{writer}->init;
   $self->{writer}->send_init_stream (
      $self->{language}, $self->{domain}, $self->{stream_namespace}
   );
}

sub handle_error {
   my ($self, $node) = @_;
   my $error = AnyEvent::XMPP::Error::Stream->new (node => $node);

   $self->event (stream_error => $error);
   $self->{writer}->send_end_of_stream;
}

# This is a hack for jabberd 1.4.2, VERY OLD Jabber stuff.
sub start_old_style_authentication {
   my ($self) = @_;

   $self->{features}
      = AnyEvent::XMPP::Node->new (
          'http://etherx.jabber.org/streams', 'features', [], $self->{parser}
        );

   my $continue = 1;
   $self->event (stream_pre_authentication => \$continue);
   if ($continue) {
      $self->do_iq_auth;
   }
}

sub do_iq_auth {
   my ($self) = @_;

   if ($self->{anal_iq_auth}) {
      $self->send_iq (get => {
         defns => 'auth', node => { ns => 'auth', name => 'query',
            # heh, something i've seen on some ejabberd site:
            # childs => [ { name => 'username', childs => [ $self->{username} ] } ] 
         }
      }, sub {
         my ($n, $e) = @_;
         if ($e) {
            $self->event (iq_auth_error =>
               AnyEvent::XMPP::Error::IQAuth->new (context => 'iq_error', iq_error => $e)
            );
         } else {
            my $fields = {};
            my (@query) = $n->find_all ([qw/auth query/]);
            if (@query) {
               for (qw/username password digest resource/) {
                  if ($query[0]->find_all ([qw/auth/, $_])) {
                     $fields->{$_} = 1;
                  }
               }

               $self->do_iq_auth_send ($fields);
            } else {
               $self->event (iq_auth_error =>
                  AnyEvent::XMPP::Error::IQAuth->new (context => 'no_fields')
               );
            }
         }
      });
   } else {
      $self->do_iq_auth_send ({ username => 1, password => 1, resource => 1 });
   }
}

sub do_iq_auth_send {
   my ($self, $fields) = @_;

   for (qw/username password resource/) {
      die "No '$_' argument given to new, but '$_' is required\n"
         unless defined $self->{$_};
   }

   my $do_resource = $fields->{resource};
   my $password = $self->{password};

   if ($fields->{digest}) {
      my $out_password = encode ("UTF-8", $password);
      my $out = lc sha1_hex ($self->stream_id () . $out_password);
      $fields = {
         username => $self->{username},
         digest => $out,
      }

   } else {
      $fields = {
         username => $self->{username},
         password => $password
      }
   }

   if ($do_resource && defined $self->{resource}) {
      $fields->{resource} = $self->{resource}
   }

   $self->send_iq (set => {
      defns => 'auth',
      node => { ns => 'auth', name => 'query', childs => [
         map { { name => $_, childs => [ $fields->{$_} ] } } reverse sort keys %$fields
      ]}
   }, sub {
      my ($n, $e) = @_;
      if ($e) {
         $self->event (iq_auth_error =>
            AnyEvent::XMPP::Error::IQAuth->new (context => 'iq_error', iq_error => $e)
         );
      } else {
         $self->{authenticated} = 1;
         $self->{jid} = join_jid ($self->{username}, $self->{domain}, $self->{resource});
         $self->event (stream_ready => $self->{jid});
      }
   });
}

=item B<send_presence ($type, $create_cb, %attrs)>

This method sends a presence stanza, for the meanings
of C<$type>, C<$create_cb> and C<%attrs> please take a look
at the documentation for C<send_presence> method of L<AnyEvent::XMPP::Writer>.

This methods does attach an id attribute to the presence stanza and
will return the id that was used (so you can react on possible replies).

=cut

sub send_presence {
   my ($self, $type, $create_cb, %attrs) = @_;
   my $id = $self->{iq_id}++;
   $self->{writer}->send_presence ($id, $type, $create_cb, %attrs);
   $id
}

=item B<send_message ($to, $type, $create_cb, %attrs)>

This method sends a message stanza, for the meanings
of C<$to>, C<$type>, C<$create_cb> and C<%attrs> please take a look
at the documentation for C<send_message> method of L<AnyEvent::XMPP::Writer>.

This methods does attach an id attribute to the message stanza and
will return the id that was used (so you can react on possible replies).

=cut

sub send_message {
   my ($self, $to, $type, $create_cb, %attrs) = @_;
   my $id = delete $attrs{id} || $self->{iq_id}++;
   $self->{writer}->send_message ($id, $to, $type, $create_cb, %attrs);
   $id
}

=item B<do_rebind ($resource)>

In case you got a C<bind_error> event and want to retry
binding you can call this function to set a new C<$resource>
and retry binding.

If it fails again you can call this again. Becareful not to
end up in a loop!

If binding was successful the C<stream_ready> event will be generated.

=cut

sub do_rebind {
   my ($self, $resource) = @_;
   $self->{resource} = $resource;
   $self->send_iq (
      set =>
         sub {
            my ($w) = @_;
            if ($self->{resource}) {
               simxml ($w,
                  defns => 'bind',
                  node => {
                     name => 'bind',
                     childs => [ { name => 'resource', childs => [ $self->{resource} ] } ]
                  }
               )
            } else {
               simxml ($w, defns => 'bind', node => { name => 'bind' })
            }
         },
         sub {
            my ($ret_iq, $error) = @_;

            if ($error) {
               # TODO: make bind error into a seperate error class?
               if ($error->xml_node ()) {
                  my ($res) = $error->xml_node ()->find_all ([qw/bind bind/], [qw/bind resource/]);
                  $self->event (bind_error => $error, ($res ? $res : $self->{resource}));
               } else {
                  $self->event (bind_error => $error);
               }

            } else {
               my @jid = $ret_iq->find_all ([qw/bind bind/], [qw/bind jid/]);
               my $jid = $jid[0]->text;
               unless ($jid) { die "Got empty JID tag from server!\n" }
               $self->{jid} = $jid;

               $self->event (stream_ready => $jid);
            }
         }
   );
}


sub _start_whitespace_ping {
   my ($self) = @_;

   return unless $self->{whitespace_ping_interval} > 0;

   $self->{_ws_ping} =
      AnyEvent->timer (after => $self->{whitespace_ping_interval}, cb => sub {
         $self->{writer}->send_whitespace_ping;
         $self->_start_whitespace_ping;
      });
}

sub _stop_whitespace_ping {
   delete $_[0]->{_ws_ping};
}


=item B<jid>

After the stream has been bound to a resource the JID can be retrieved via this
method.

=cut

sub jid { $_[0]->{jid} }

=item B<features>

Returns the last received <features> tag in form of an L<AnyEvent::XMPP::Node> object.

=cut

sub features { $_[0]->{features} }

=item B<stream_id>

This is the ID of this stream that was given us by the server.

=cut

sub stream_id { $_[0]->{stream_id} }

=back

=head1 EVENTS

The L<AnyEvent::XMPP::Connection> class is derived from the L<Object::Event> class,
and thus inherits the event callback registering system from it. Consult the
documentation of L<Object::Event> about more details.

NODE: Every callback gets as it's first argument the L<AnyEvent::XMPP::Connection>
object. The further callback arguments are described in the following listing of
events.

These events can be registered on with C<reg_cb>:

=over 4

=item stream_features => $node

This event is sent when a stream feature (<features>) tag is received. C<$node> is the
L<AnyEvent::XMPP::Node> object that represents the <features> tag.

=item stream_pre_authentication

This event is emitted after TLS/SSL was initiated (if enabled) and before any
authentication happened.

The return value of the first event callback that is called decides what happens next.
If it is true value the authentication continues. If it is undef or a false value
authentication is stopped and you need to call C<authentication> later.
value

This event is usually used when you want to do in-band registration,
see also L<AnyEvent::XMPP::Ext::Registration>.

=item stream_ready => $jid

This event is sent if the XML stream has been established (and
resources have been bound) and is ready for transmitting regular stanzas.

C<$jid> is the bound jabber id.

=item error => $error

This event is generated whenever some error occured.
C<$error> is an instance of L<AnyEvent::XMPP::Error>.
Trivial error reporting may look like this:

   $con->reg_cb (error => sub { warn "xmpp error: " . $_[1]->string . "\n" });

Basically this event is a collect event for all other error events.

=item stream_error => $error

This event is sent if a XML stream error occured. C<$error>
is a L<AnyEvent::XMPP::Error::Stream> object.

=item xml_parser_error => $error

This event is generated whenever the parser trips over XML that it can't
read. C<$error> is a L<AnyEvent::XMPP::Error::Parser> object.

=item tls_error

This event is emitted when a TLS error occured on TLS negotiation.
After this the connection will be disconnected.

=item sasl_error => $error

This event is emitted on SASL authentication error.

=item iq_auth_error => $error

This event is emitted when IQ authentication (XEP-0078) failed.

=item bind_error => $error, $resource

This event is generated when the stream was unable to bind to
any or the in C<new> specified resource. C<$error> is a L<AnyEvent::XMPP::Error::IQ>
object. C<$resource> is the errornous resource string or undef if none
was received.

The C<condition> of the C<$error> might be one of: 'bad-request',
'not-allowed' or 'conflict'.

Node: this is untested, I couldn't get the server to send a bind error
to test this.

=item connect => $host, $port

This event is generated when a successful TCP connect was performed to
the domain passed to C<new>.

Note: C<$host> and C<$port> might be different from the domain you passed to
C<new> if C<connect> performed a SRV RR lookup.

If this connection is lost a C<disconnect> will be generated with the same
C<$host> and C<$port>.

=item disconnect => $host, $port, $message

This event is generated when the TCP connection was lost or another error
occurred while writing or reading from it.

C<$message> is a human readable error message for the failure.
C<$host> and C<$port> were the host and port we were connected to.

Note: C<$host> and C<$port> might be different from the domain you passed to
C<new> if C<connect> performed a SRV RR lookup.

=item recv_stanza_xml => $node, $rstop

This event is generated before any processing of a "XML" stanza happens.
C<$node> is the node of the stanza that is being processed, it's of
type L<AnyEvent::XMPP::Node>.

This method might not be as handy for debugging purposes as C<debug_recv>.

If you want to handle the stanza yourself and don't want this module
to take care of it set a true value to the scalar referenced by C<$rstop>.

=item send_stanza_data => $data

This event is generated shortly before data is sent to the socket.
C<$data> contains a complete "XML" stanza or the end of stream closing
tag. This method is useful for debugging purposes and I recommend
using XML::Twig or something like that to display it nicely.

See also the event C<debug_send>.

=item debug_send => $data

This method is invoked whenever data is written out. This event
is mostly the same as C<send_stanza_data>.

=item debug_recv => $data

This method is invoked whenever a chunk of data was received.

It works to filter C<$data> through L<XML::Twig> for debugging
display purposes sometimes, but as C<$data> is some arbitrary chunk
of bytes you might get a XML parse error (did I already mention that XMPP's
application of "XML" sucks?).

So you might want to use C<recv_stanza_xml> to detect
complete stanzas. Unfortunately C<recv_stanza_xml> doesn't have the
bytes anymore and just a data structure (L<AnyEvent::XMPP::Node>).

=item send_buffer_empty

This event is VERY useful if you want to wait (or at least be notified)
when the output buffer is empty. If you got a bunch of messages to sent
or even one and you want to do something when the output buffer is empty,
you can wait for this event. It is emitted every time the output buffer is
completely written out to the kernel.

Here is an example:

   $con->reg_cb (send_buffer_empty => sub {
      $con->disconnect ("wrote message, going to disconnect now...");
   });
   $con->send_message ("Test message!" => 'elmex@jabber.org', undef, 'chat');

=item presence_xml => $node

This event is sent when a presence stanza is received. C<$node> is the
L<AnyEvent::XMPP::Node> object that represents the <presence> tag.

If you want to overtake the handling of the stanza, see C<iq_xml>
below.

=item message_xml => $node

This event is sent when a message stanza is received. C<$node> is the
L<AnyEvent::XMPP::Node> object that represents the <message> tag.

If you want to overtake the handling of the stanza, see C<iq_xml>
below.

=item iq_xml => $node

This event is emitted when a iq stanza arrives. C<$node> is the
L<AnyEvent::XMPP::Node> object that represents the <iq> tag.

If you want to overtake the handling of a stanza, you should
register a callback for the C<before_iq_xml> event and call the
C<stop_event> method. See also L<Object::Event>. This is an example:

   $con->reg_cb (before_iq_xml => sub {
      my ($con, $node) = @_;

      if (...) {
         # and stop_event will stop internal handling of the stanza:
         $con->stop_event;
      }
   });

Please note that if you overtake handling of a stanza none of the internal
handling of that stanza will be done. That means you won't get events
like C<iq_set_request_xml> anymore.

=item iq_set_request_xml => $node, $rhandled

=item iq_get_request_xml => $node, $rhandled

These events are sent when an iq request stanza of type 'get' or 'set' is received.
C<$type> will either be 'get' or 'set' and C<$node> will be the L<AnyEvent::XMPP::Node>
object of the iq tag.

To signal the stanza was handled set the scalar referenced by C<$rhandled>
to a true value.
If the stanza was not handled an error iq will be generated.

=item iq_result_cb_exception => $exception

If the C<$result_cb> of a C<send_iq> operation somehow threw a exception
or failed this event will be generated.

=item send_iq_hook => $id, $type, $attrs, \@create_cb

This event lets you add any desired number of additional create callbacks
to a IQ stanza that is about to be sent.

C<$id>, C<$type> are described in the documentation of C<send_iq> of
L<AnyEvent::XMPP::Writer>. C<$attrs> is the hashref to the C<%attrs> hash that can
be passed to C<send_iq> and also has the exact same semantics as described in
the documentation of C<send_iq>.

You can push values into C<create_cb> (as documented for C<send_iq>), for
example a callback that fills the IQ.

Example:

   # this appends a <test/> element to all outgoing IQs
   # and also a <test2/> element to all outgoing IQs
   $con->reg_cb (send_iq_hook => sub {
      my ($con, $id, $type, $attrs, $create_cb) = @_;
      push @$create_cb, sub {
         my $w = shift; # $w is a XML::Writer instance
         $w->emptyTag ('test');
      };
      push @$create_cb, {
         node => { name => "test2" } # see also simxml() defined in AnyEvent::XMPP::Util
      };
   });

=item send_message_hook => $id, $to, $type, $attrs, \@create_cb

This event lets you add any desired number of additional create callbacks
to a message stanza that is about to be sent.

C<$id>, C<$to>, C<$type> and the hashref C<$attrs> are described in the documentation
for C<send_message> of L<AnyEvent::XMPP::Writer> (C<$attrs> is C<%attrs> there).

To actually append something you need to push into C<create_cb> as described in
the C<send_iq_hook> event above.

=item send_presence_hook => $id, $type, $attrs, \@create_cb

This event lets you add any desired number of additional create callbacks
to a presence stanza that is about to be sent.

C<$id>, C<$type> and the hashref C<$attrs> are described in the documentation
for C<send_presence> of L<AnyEvent::XMPP::Writer> (C<$attrs> is C<%attrs> there).

To actually append something you need to push into C<create_cb> as described in
the C<send_iq_hook> event above.

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 CONTRIBUTORS

melo - minor fixes

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP
