=head1 NAME

AnyEvent::MP::Transport - actual transport protocol handler

=head1 SYNOPSIS

   use AnyEvent::MP::Transport;

=head1 DESCRIPTION

This module implements (and documents) the actual transport protocol for
AEMP.

See the "PROTOCOL" section below if you want to write another client for
this protocol.

=head1 FUNCTIONS/METHODS

=over 4

=cut

package AnyEvent::MP::Transport;

use common::sense;

use Scalar::Util ();
use List::Util ();
use MIME::Base64 ();
use Storable ();
use JSON::XS ();

use Digest::MD6 ();
use Digest::HMAC_MD6 ();

use AE ();
use AnyEvent::Socket ();
use AnyEvent::Handle 4.92 ();

use AnyEvent::MP::Config ();

our $PROTOCOL_VERSION = 1;

our @HOOK_CONNECT;   # called at connect/accept time
our @HOOK_GREETING;  # called at greeting1 time
our @HOOK_CONNECTED; # called at data phase
our @HOOK_DESTROY;   # called at destroy time
our %HOOK_PROTOCOL = (
   "aemp-dataconn" => sub {
      require AnyEvent::MP::DataConn;
      &AnyEvent::MP::DataConn::_inject;
   },
);

=item $listener = mp_listener $host, $port, <constructor-args>

Creates a listener on the given host/port using
C<AnyEvent::Socket::tcp_server>.

See C<new>, below, for constructor arguments.

Defaults for peerhost, peerport and fh are provided.

=cut

sub mp_server($$;%) {
   my ($host, $port, %arg) = @_;

   AnyEvent::Socket::tcp_server $host, $port, sub {
      my ($fh, $host, $port) = @_;

      my $tp = new AnyEvent::MP::Transport
         fh       => $fh,
         peerhost => $host,
         peerport => $port,
         %arg,
      ;
      $tp->{keepalive} = $tp;
   }, delete $arg{prepare}
}

=item $guard = mp_connect $host, $port, <constructor-args>, $cb->($transport)

=cut

sub mp_connect {
   my $release = pop;
   my ($host, $port, @args) = @_;

   new AnyEvent::MP::Transport
      connect  => [$host, $port],
      peerhost => $host,
      peerport => $port,
      release  => $release,
      @args,
   ;
}

=item new AnyEvent::MP::Transport

   # immediately starts negotiation
   my $transport = new AnyEvent::MP::Transport
      # mandatory
      fh       => $filehandle,
      local_id => $identifier,
      on_recv  => sub { receive-callback },
      on_error => sub { error-callback },

      # optional
      on_eof   => sub { clean-close-callback },
      on_connect => sub { successful-connect-callback },
      greeting => { key => value },

      # tls support
      tls_ctx  => AnyEvent::TLS,
      peername => $peername, # for verification
   ;

=cut

sub new {
   my ($class, %arg) = @_;

   my $self = bless \%arg, $class;

   {
      Scalar::Util::weaken (my $self = $self);

      my $config = $AnyEvent::MP::Kernel::CONFIG;

      my $timeout  = $config->{monitor_timeout};
      my $lframing = $config->{framing_format};
      my $auth_snd = $config->{auth_offer};
      my $auth_rcv = $config->{auth_accept};

      $self->{secret} = $config->{secret}
         unless exists $self->{secret};

      my $secret = $self->{secret};

      if (exists $config->{cert}) {
         $self->{tls_ctx} = {
            sslv2   => 0,
            sslv3   => 0,
            tlsv1   => 1,
            verify  => 1,
            cert    => $config->{cert},
            ca_cert => $config->{cert},
            verify_require_client_cert => 1,
         };
      }

      $self->{hdl} = new AnyEvent::Handle
         +($self->{fh} ? (fh => $self->{fh}) : (connect => $self->{connect})),
         autocork  => $config->{autocork},
         no_delay  => exists $config->{nodelay} ? $config->{nodelay} : 1,
         keepalive => 1,
         on_error  => sub {
            $self->error ($_[2]);
         },
         rtimeout  => $timeout,
      ;

      my $greeting_kv = $self->{local_greeting} ||= {};

      $greeting_kv->{tls}      = "1.0" if $self->{tls_ctx};
      $greeting_kv->{provider} = "AE-$AnyEvent::MP::VERSION"; # MP.pm might not be loaded, so best effort :(
      $greeting_kv->{peeraddr} = AnyEvent::Socket::format_hostport $self->{peerhost}, $self->{peerport};

      my $protocol = $self->{protocol} || "aemp";

      # can modify greeting_kv
      $_->($self) for $protocol eq "aemp" ? @HOOK_CONNECT : ();

      # send greeting
      my $lgreeting1 = "$protocol;$PROTOCOL_VERSION"
                     . ";$AnyEvent::MP::Kernel::NODE"
                     . ";" . (join ",", @$auth_rcv)
                     . ";" . (join ",", @$lframing)
                     . (join "", map ";$_=$greeting_kv->{$_}", keys %$greeting_kv);

      my $lgreeting2 = MIME::Base64::encode_base64 AnyEvent::MP::Kernel::nonce (66), "";

      $self->{hdl}->push_write ("$lgreeting1\012$lgreeting2\012");
      return unless $self;

      # expect greeting
      $self->{hdl}->rbuf_max (4 * 1024);
      $self->{hdl}->push_read (line => sub {
         my $rgreeting1 = $_[1];

         my ($aemp, $version, $rnode, $auths, $framings, @kv) = split /;/, $rgreeting1;

         $self->{remote_node} = $rnode;

         $self->{remote_greeting} = {
            map /^([^=]+)(?:=(.*))?/ ? ($1 => $2) : (),
               @kv
         };

         # maybe upgrade the protocol
         if ($protocol eq "aemp" and $aemp =~ /^aemp-\w+$/) {
            # maybe check for existence of the protocol handler?
            $self->{protocol} = $protocol = $aemp;
         }

         $_->($self) for $protocol eq "aemp" ? @HOOK_GREETING : ();

         if ($aemp ne $protocol and $aemp ne "aemp") {
            return $self->error ("unparsable greeting, expected '$protocol', got '$aemp'");
         } elsif ($version != $PROTOCOL_VERSION) {
            return $self->error ("version mismatch (we: $PROTOCOL_VERSION, they: $version)");
         } elsif ($protocol eq "aemp") {
            if ($rnode eq $AnyEvent::MP::Kernel::NODE) {
               return $self->error ("I refuse to talk to myself");
            } elsif ($AnyEvent::MP::Kernel::NODE{$rnode} && $AnyEvent::MP::Kernel::NODE{$rnode}{transport}) {
               return $self->error ("$rnode already connected, not connecting again.");
            }
         }

         # read nonce
         $self->{hdl}->push_read (line => sub {
            my $rgreeting2 = $_[1];

            "$lgreeting1\012$lgreeting2" ne "$rgreeting1\012$rgreeting2" # echo attack?
               or return $self->error ("authentication error, echo attack?");

            my $tls = $self->{tls_ctx} && 1 == int $self->{remote_greeting}{tls};

            my $s_auth;
            for my $auth_ (split /,/, $auths) {
               if (grep $auth_ eq $_, @$auth_snd and ($auth_ !~ /^tls_/ or $tls)) {
                  $s_auth = $auth_;
                  last;
               }
            }

            defined $s_auth
               or return $self->error ("$auths: no common auth type supported");

            my $s_framing;
            for my $framing_ (split /,/, $framings) {
               if (grep $framing_ eq $_, @$lframing) {
                  $s_framing = $framing_;
                  last;
               }
            }

            defined $s_framing
               or return $self->error ("$framings: no common framing method supported");

            my $key;
            my $lauth;

            if ($tls) {
               $self->{tls} = $lgreeting2 lt $rgreeting2 ? "connect" : "accept";
               $self->{hdl}->starttls ($self->{tls}, $self->{tls_ctx});
               return unless $self->{hdl}; # starttls might destruct us

               $lauth =
                  $s_auth eq "tls_anon"       ? ""
                : $s_auth eq "tls_md6_64_256" ? Digest::MD6::md6_hex "$lgreeting1\012$lgreeting2\012$rgreeting1\012$rgreeting2\012"
                : return $self->error ("$s_auth: fatal, selected unsupported snd auth method");

            } elsif (length $secret) {
               return $self->error ("$s_auth: fatal, selected unsupported snd auth method")
                  unless $s_auth eq "hmac_md6_64_256"; # hardcoded atm.

               $key = Digest::MD6::md6 $secret;
               # we currently only support hmac_md6_64_256
               $lauth = Digest::HMAC_MD6::hmac_md6_hex $key, "$lgreeting1\012$lgreeting2\012$rgreeting1\012$rgreeting2\012", 64, 256;

            } else {
               return $self->error ("unable to handshake TLS and no shared secret configured");
            }

            $self->{hdl}->push_write ("$s_auth;$lauth;$s_framing\012");
            return unless $self;

            # read the authentication response
            $self->{hdl}->push_read (line => sub {
               my ($hdl, $rline) = @_;

               my ($auth_method, $rauth2, $r_framing) = split /;/, $rline;

               my $rauth =
                  $auth_method eq "hmac_md6_64_256" ? Digest::HMAC_MD6::hmac_md6_hex $key, "$rgreeting1\012$rgreeting2\012$lgreeting1\012$lgreeting2\012", 64, 256
                : $auth_method eq "cleartext"       ? unpack "H*", $secret
                : $auth_method eq "tls_anon"        ? ($tls ? "" : "\012\012") # \012\012 never matches
                : $auth_method eq "tls_md6_64_256"  ? ($tls ? Digest::MD6::md6_hex "$rgreeting1\012$rgreeting2\012$lgreeting1\012$lgreeting2\012" : "\012\012")
                : return $self->error ("$auth_method: fatal, selected unsupported rcv auth method");

               if ($rauth2 ne $rauth) {
                  return $self->error ("authentication failure/shared secret mismatch");
               }

               $self->{s_framing} = $s_framing;

               $hdl->rbuf_max (undef);

               # we rely on TCP retransmit timeouts and keepalives
               $self->{hdl}->rtimeout (undef);

               $self->{remote_greeting}{untrusted} = 1
                  if $auth_method eq "tls_anon";

               if ($protocol eq "aemp" and $self->{hdl}) {
                  # listener-less node need to continuously probe
                  unless (@$AnyEvent::MP::Kernel::LISTENER) {
                     $self->{hdl}->wtimeout ($timeout);
                     $self->{hdl}->on_wtimeout (sub { $self->{send}->([]) });
                  }

                  # receive handling

                  my $push_write = $hdl->can ("push_write");
                  my $push_read  = $hdl->can ("push_read");

                  if ($s_framing eq "json") {
                     $self->{send} = sub {
                        $push_write->($hdl, JSON::XS::encode_json $_[0]);
                     };
                  } else {
                     $self->{send} = sub {
                        $push_write->($hdl, $s_framing => $_[0]);
                     };
                  }

                  if ($r_framing eq "json") {
                     my $coder = JSON::XS->new->utf8;

                     $hdl->on_read (sub {
                        local $AnyEvent::MP::Kernel::SRCNODE = $self->{node};

                        AnyEvent::MP::Kernel::_inject (@$_)
                           for $coder->incr_parse (delete $_[0]{rbuf});

                        ()
                     });
                  } else {
                     my $rmsg; $rmsg = $self->{rmsg} = sub {
                        $push_read->($_[0], $r_framing => $rmsg);

                        local $AnyEvent::MP::Kernel::SRCNODE = $self->{node};
                        AnyEvent::MP::Kernel::_inject (@{ $_[1] });
                     };
                     eval {
                        $push_read->($_[0], $r_framing => $rmsg);
                     };
                     Scalar::Util::weaken $rmsg;
                     return $self->error ("$r_framing: unusable remote framing")
                        if $@;
                  }
               }

               $self->connected;
            });
         });
      });
   }

   $self
}

sub error {
   my ($self, $msg) = @_;

   delete $self->{keepalive};

   if ($self->{protocol}) {
      $HOOK_PROTOCOL{$self->{protocol}}->($self, $msg);
   } else {
      $AnyEvent::MP::Kernel::WARN->(9, "$self->{peerhost}:$self->{peerport} $msg");#d#

      $self->{node}->transport_error (transport_error => $self->{node}{id}, $msg)
         if $self->{node} && $self->{node}{transport} == $self;
   }

   (delete $self->{release})->()
      if exists $self->{release};
   
#   $AnyEvent::MP::Kernel::WARN->(7, "$self->{peerhost}:$self->{peerport}: $msg");
   $self->destroy;
}

sub connected {
   my ($self) = @_;

   delete $self->{keepalive};

   if ($self->{protocol}) {
      $self->{hdl}->on_error (undef);
      $HOOK_PROTOCOL{$self->{protocol}}->($self, undef);
   } else {
      $AnyEvent::MP::Kernel::WARN->(9, "$self->{peerhost}:$self->{peerport} connected as $self->{remote_node}");

      my $node = AnyEvent::MP::Kernel::add_node ($self->{remote_node});
      Scalar::Util::weaken ($self->{node} = $node);
      $node->transport_connect ($self);

      $_->($self) for @HOOK_CONNECTED;
   }

   (delete $self->{release})->()
      if exists $self->{release};
}

sub destroy {
   my ($self) = @_;

   (delete $self->{release})->()
      if exists $self->{release};

   $self->{hdl}->destroy
      if $self->{hdl};

   $_->($self) for $self->{protocol} ? () : @HOOK_DESTROY;
}

sub DESTROY {
   my ($self) = @_;

   $self->destroy;
}

=back

=head1 PROTOCOL

The AEMP protocol is comparatively simple, and consists of three phases
which are symmetrical for both sides: greeting (followed by optionally
switching to TLS mode), authentication and packet exchange.

The protocol is designed to allow both full-text and binary streams.

The greeting consists of two text lines that are ended by either an ASCII
CR LF pair, or a single ASCII LF (recommended).

=head2 GREETING

All the lines until after authentication must not exceed 4kb in length,
including line delimiter. Afterwards there is no limit on the packet size
that can be received.

=head3 First Greeting Line

Example:

   aemp;0;rain;tls_md6_64_256,hmac_md6_64_256,tls_anon,cleartext;json,storable;timeout=12;peeraddr=10.0.0.1:48082

The first line contains strings separated (not ended) by C<;>
characters. The first five strings are fixed by the protocol, the
remaining strings are C<KEY=VALUE> pairs. None of them may contain C<;>
characters themselves (when escaping is needed, use C<%3b> to represent
C<;> and C<%25> to represent C<%>)-

The fixed strings are:

=over 4

=item protocol identification

The constant C<aemp> to identify this protocol.

=item protocol version

The protocol version supported by this end, currently C<1>. If the
versions don't match then no communication is possible. Minor extensions
are supposed to be handled through additional key-value pairs.

=item the node ID

This is the node ID of the connecting node.

=item the acceptable authentication methods

A comma-separated list of authentication methods supported by the
node. Note that AnyEvent::MP supports a C<hex_secret> authentication
method that accepts a clear-text password (hex-encoded), but will not use
this authentication method itself.

The receiving side should choose the first authentication method it
supports.

=item the acceptable framing formats

A comma-separated list of packet encoding/framing formats understood. The
receiving side should choose the first framing format it supports for
sending packets (which might be different from the format it has to accept).

=back

The remaining arguments are C<KEY=VALUE> pairs. The following key-value
pairs are known at this time:

=over 4

=item provider=<module-version>

The software provider for this implementation. For AnyEvent::MP, this is
C<AE-0.0> or whatever version it currently is at.

=item peeraddr=<host>:<port>

The peer address (socket address of the other side) as seen locally.

=item tls=<major>.<minor>

Indicates that the other side supports TLS (version should be 1.0) and
wishes to do a TLS handshake.

=back

=head3 Second Greeting Line

After this greeting line there will be a second line containing a
cryptographic nonce, i.e. random data of high quality. To keep the
protocol text-only, these are usually 32 base64-encoded octets, but
it could be anything that doesn't contain any ASCII CR or ASCII LF
characters.

I<< The two nonces B<must> be different, and an aemp implementation
B<must> check and fail when they are identical >>.

Example of a nonce line (yes, it's random-looking because it is random
data):

   2XYhdG7/O6epFa4wuP0ujAEx1rXYWRcOypjUYK7eF6yWAQr7gwIN9m/2+mVvBrTPXz5GJDgfGm9d8QRABAbmAP/s

=head2 TLS handshake

I<< If, after the handshake, both sides indicate interest in TLS, then the
connection B<must> use TLS, or fail to continue. >>

Both sides compare their nonces, and the side who sent the lower nonce
value ("string" comparison on the raw octet values) becomes the client,
and the one with the higher nonce the server.

=head2 AUTHENTICATION PHASE

After the greeting is received (and the optional TLS handshake),
the authentication phase begins, which consists of sending a single
C<;>-separated line with three fixed strings and any number of
C<KEY=VALUE> pairs.

The three fixed strings are:

=over 4

=item the authentication method chosen

This must be one of the methods offered by the other side in the greeting.

Note that all methods starting with C<tls_> are only valid I<iff> TLS was
successfully handshaked (and to be secure the implementation must enforce
this).

The currently supported authentication methods are:

=over 4

=item cleartext

This is simply the shared secret, lowercase-hex-encoded. This method is of
course very insecure if TLS is not used (and not completely secure even
if TLS is used), which is why this module will accept, but not generate,
cleartext auth replies.

=item hmac_md6_64_256

This method uses an MD6 HMAC with 64 bit blocksize and 256 bit hash, and
requires a shared secret. It is the preferred auth method when a shared
secret is available.

First, the shared secret is hashed with MD6:

   key = MD6 (secret)

This secret is then used to generate the "local auth reply", by taking
the two local greeting lines and the two remote greeting lines (without
line endings), appending \012 to all of them, concatenating them and
calculating the MD6 HMAC with the key:

   lauth = HMAC_MD6 key, "lgreeting1\012lgreeting2\012rgreeting1\012rgreeting2\012"

This authentication token is then lowercase-hex-encoded and sent to the
other side.

Then the remote auth reply is generated using the same method, but local
and remote greeting lines swapped:

   rauth = HMAC_MD6 key, "rgreeting1\012rgreeting2\012lgreeting1\012lgreeting2\012"

This is the token that is expected from the other side.

=item tls_anon

This type is only valid I<iff> TLS was enabled and the TLS handshake
was successful. It has no authentication data, as the server/client
certificate was successfully verified.

This authentication type is somewhat insecure, as it allows a
man-in-the-middle attacker to change some of the connection parameters
(such as the framing format), although there is no known attack that
exploits this in a way that is worse than just denying the service.

By default, this implementation accepts but never generates this auth
reply.

=item tls_md6_64_256

This type is only valid I<iff> TLS was enabled and the TLS handshake was
successful.

This authentication type simply calculates:

   lauth = MD6 "rgreeting1\012rgreeting2\012lgreeting1\012lgreeting2\012"

and lowercase-hex encodes the result and sends it as authentication
data. No shared secret is required (authentication is done by TLS). The
checksum exists only to make tinkering with the greeting hard.

=back

=item the authentication data

The authentication data itself, usually base64 or hex-encoded data, see
above.

=item the framing protocol chosen

This must be one of the framing protocols offered by the other side in the
greeting. Each side must accept the choice of the other side, and generate
packets in the format it chose itself.

=back

Example of an authentication reply:

   hmac_md6_64_256;363d5175df38bd9eaddd3f6ca18aa1c0c4aa22f0da245ac638d048398c26b8d3;json

=head2 DATA PHASE

After this, packets get exchanged using the chosen framing protocol. It is
quite possible that both sides use a different framing protocol.

=head2 FULL EXAMPLE

This is an actual protocol dump of a handshake, followed by a single data
packet. The greater than/less than lines indicate the direction of the
transfer only.

   > aemp;0;anon/57Cs1CggVJjzYaQp13XXg4;tls_md6_64_256,hmac_md6_64_256,tls_anon,cleartext;json,storable;provider=AE-0.8;timeout=12;peeraddr=10.0.0.17:4040
   > yLgdG1ov/02shVkVQer3wzeuywZK+oraTdEQBmIqWHaegxSGDG4g+HqogLQbvdypFOsoDWJ1Sh4ImV4DMhvUBwTK

   < aemp;0;ruth;tls_md6_64_256,hmac_md6_64_256,tls_anon,cleartext;json,storable;provider=AE-0.8;timeout=12;peeraddr=10.0.0.1:37108
   < +xMQXP8ElfNmuvEhsmcp+s2wCJOuQAsPxSg3d2Ewhs6gBnJz+ypVdWJ/wAVrXqlIJfLeVS/CBy4gEGkyWHSuVb1L

   > hmac_md6_64_256;5ad913855742ae5a03a5aeb7eafa4c78629de136bed6acd73eea36c9e98df44a;json

   < hmac_md6_64_256;84cd590976f794914c2ca26dac3a207a57a6798b9171289c114de07cf0c20401;json
   < ["","AnyEvent::MP::_spawn","57Cs1CggVJjzYaQp13XXg4.c","AnyEvent::MP::Global::connect",0,"anon/57Cs1CggVJjzYaQp13XXg4"]
   ...

The shared secret in use was C<8ugxrtw6H5tKnfPWfaSr4HGhE8MoJXmzTT1BWq7sLutNcD0IbXprQlZjIbl7MBKoeklG3IEfY9GlJthC0pENzk>.

=head2 SIMPLE HANDSHAKE FOR NON-PERL NODES

Implementing the full set of options for handshaking can be a daunting
task.

If security is not so important (because you only connect locally and
control the host, a common case), and you want to interface with an AEMP
node from another programming language, then you can also implement a
simplified handshake.

For example, in a simple implementation you could decide to simply not
check the authenticity of the other side and use cleartext authentication
yourself. The the handshake is as simple as sending three lines of text,
reading three lines of text, and then you can exchange JSON-formatted
messages:

   aemp;1;<nodename>;hmac_md6_64_256;json
   <nonce>
   cleartext;<hexencoded secret>;json

The nodename should be unique within the network, preferably unique with
every connection, the <nonce> could be empty or some random data, and the
hexencoded secret would be the shared secret, in lowercase hex (e.g. if
the secret is "geheim", the hex-encoded version would be "67656865696d").

Note that apart from the low-level handshake and framing protocol, there
is a high-level protocol, e.g. for monitoring, building the mesh or
spawning. All these messages are sent to the node port (the empty string)
and can safely be ignored if you do not need the relevant functionality.

=head3 USEFUL HINTS

Since taking part in the global protocol to find port groups is
nontrivial, hardcoding port names should be considered as well, i.e. the
non-Perl node could simply listen to messages for a few well-known ports.

Alternatively, the non-Perl node could call a (already loaded) function
in the Perl node by sending it a special message:

   ["", "Some::Function::name", "myownport", 1, 2, 3]

This would call the function C<Some::Function::name> with the string
C<myownport> and some additional arguments.

=head2 MONITORING

Monitoring the connection itself is transport-specific. For TCP, all
connection monitoring is currently left to TCP retransmit time-outs
on a busy link, and TCP keepalive (which should be enabled) for idle
connections.

This is not sufficient for listener-less nodes, however: they need
to regularly send data (30 seconds, or the monitoring interval, is
recommended), so TCP actively probes.

Future implementations of AnyEvent::Transport might query the kernel TCP
buffer after a write timeout occurs, and if it is non-empty, shut down the
connections, but this is an area of future research :)

=head2 NODE PROTOCOL

The transport simply transfers messages, but to implement a full node, a
special node port must exist that understands a number of requests.

If you are interested in implementing this, drop us a note so we finish
the documentation.

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

