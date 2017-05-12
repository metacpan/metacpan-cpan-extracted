=head1 NAME

AnyEvent::Porttracker - Porttracker/PortIQ API client interface.

=head1 SYNOPSIS

   use AnyEvent::Porttracker;

   my $api = new AnyEvent::Porttracker
      host => "10.0.0.1",
      user => "admin",
      pass => "31331",
      tls  => 1,
   ;

   # Example 1
   # a simple request: ping the server synchronously

   my ($timestamp, $pid) = $api->req_sync ("ping");

   # Example 2
   # find all realms, start a discovery on all of them
   # and wait until all discovery processes have finished
   # but execute individual discoveries in parallel,
   # asynchronously

   my $cv = AE::cv;

   $cv->begin;
   # find all realms
   $api->req (realm_info => ["gid", "name"], sub {
      my ($api, @realms) = @_;

      # start discovery on all realms
      for my $realm (@realms) {
         my ($gid, $name) = @$realm;

         $cv->begin;
         $api->req (realm_discover => $gid, sub {
            warn "discovery for realm '$name' finished\n";
            $cv->end;
         });
      }

      $cv->end;
   });

   $cv->recv;

   # Example 3
   # subscribe to realm_poll_stop events and report each occurance

   $api->req (subscribe => "realm_poll_stop", sub {});
   $api->on (realm_poll_stop_event => sub {
      my ($api, $gid) = @_;
      warn "this just in: poll for realm <$gid> finished.\n";
   });

   AE::cv->recv; # wait forever

=head1 DESCRIPTION

Porttracker (L<http://www.porttracker.com/>) is a product that (among
other things) scans switches and routers in a network and gives a coherent
view of which end devices are connected to which switch ports on which
switches and routers. It also offers a JSON-based client API, for which
this module is an implementation.

In addition to Porttracker, the PortIQ product is also supported, as it
uses the same protocol.

If you do not have access to either a Porttracker or PortIQ box then this
module will be of little value to you.

This module is an L<AnyEvent> user, you need to make sure that you use and
run a supported event loop.

To quickly understand how this module works you should read how to
construct a new connection object and then read about the event/callback
system.

The actual low-level protocol and, more importantly, the existing
requests and responses, are documented in the official Porttracker
API documentation (a copy of which is included in this module as
L<AnyEvent::Porttracker::protocol>.

=head1 THE AnyEvent::Porttracker CLASS

The AnyEvent::Porttracker class represents a single connection.

=over 4

=cut

package AnyEvent::Porttracker;

use common::sense;

use Carp ();
use Scalar::Util ();

use AnyEvent ();
use AnyEvent::Handle ();

use MIME::Base64 ();
use Digest::HMAC_MD6 ();
use JSON ();

our $VERSION = '1.01';

sub call {
   my ($self, $type, @args) = @_;

   $self->{$type}
      ? $self->{$type}($self, @args)
      : ($type = (UNIVERSAL::can $self, $type))
         ? $type->($self, @args)
         : ()
}

=item $api = new AnyEvent::Porttracker [key => value...]

Creates a new porttracker API connection object and tries to connect to
the specified host (see below). After the connection has been established,
the TLS handshake (if requested) will take place, followed by a login
attempt using either the C<none>, C<login_cram_md6> or C<login> methods,
in this order of preference (typically, C<login_cram_md6> is used, which
shields against some man-in-the-middle attacks and avoids transferring the
password).

It is permissible to send requests immediately after creating the object -
they will be queued until after successful login.

Possible key-value pairs are:

=over 4

=item host => $hostname [MANDATORY]

The hostname or IP address of the Porttracker box.

=item port => $service

The service (port) to use (default: C<porttracker=55>).

=item user => $string, pass => $string

These are the username and password to use when authentication is required
(which it is in almost all cases, so these keys are normally mandatory).

=item tls => $bool

Enables or disables TLS (default: disables). When enabled, then the
connection will try to handshake a TLS connection before logging in. If
unsuccessful a fatal error will be raised.

Since most Porttracker/PortIQ boxes will not have a sensible/verifiable
certificate, no attempt at verifying it will be done (which means
man-in-the-middle-attacks will be trivial). If you want some form of
verification you need to provide your own C<tls_ctx> object with C<<
verify => 1, verify_peername => [1, 1, 1] >> or whatever verification mode
you wish to use.

=item tls_ctx => $tls_ctx

The L<AnyEvent::TLS> object to use. See C<tls>, above.

=item on_XYZ => $coderef

You can specify event callbacks either by sub-classing and overriding the
respective methods or by specifying code-refs as key-value pairs when
constructing the object. You add or remove event handlers at any time with
the C<event> method.

=back

=cut

sub new {
   my $class = shift;

   my $self = bless {
      id    => "a",
      ids   => [],
      queue => [], # initially queue everything
      @_,
   }, $class;

   {
      Scalar::Util::weaken (my $self = $self);

      $self->{hdl} = new AnyEvent::Handle
         connect  => [$self->{host}, $self->{port} || "porttracker=55"],
         on_error => sub {
            $self->error ($_[2]);
         },
         on_connect => sub {
            if ($self->{tls}) {
               $self->_req (start_tls => sub {
                  $_[1]
                     or return $self->error ("TLS rejected by server");

                  $self->_login;
               });
            }
         },
         on_read  => sub {
            while ($_[0]{rbuf} =~ s/^([^\x0a]*)\x0a//) {
               my $msg = JSON::decode_json $1;
               my $id = shift @$msg;

               if (defined $id) {
                  my $cb = delete $self->{cb}{$id}
                     or return $self->error ("received unexpected reply msg with id $id");

                  push @{ $self->{ids} }, $id;

                  $cb->($self, @$msg);
               } else {
                  $msg->[0] = "on_$msg->[0]_notify";
                  call $self, @$msg;
               }
            }
         },
      ;
   }

   $self
}

sub DESTROY {
   my ($self) = @_;

   $self->{hdl}->destroy
      if $self->{hdl};
}

sub error {
   my ($self, $msg) = @_;

   call $self, on_error => $msg;

   ()
}

sub _req {
   my $self = shift;
   my $cb   = pop;

   my $id   = (pop @{ $self->{ids} }) || $self->{id}++;

   unshift @_, $id;
   $self->{cb}{$id} = $cb;

   my $msg = JSON::encode_json \@_;

   $self->{hdl}->push_write ($msg);
}

=item $api->req ($type => @args, $callback->($api, @reply))

Sends a generic request of type C<$type> to the server. When the server
responds, the API object and the response arguments (without the success
status) are passed to the callback, which is the last argument to this
method.

If the request fails, then a fatal error will be raised. If you want to
handle failures gracefully, you need to use C<< ->req_failok >> instead.

The available requests are documented in the Porttracker API
documentation (a copy of which is included in this module as
L<AnyEvent::Porttracker::protocol>.

It is permissible to call this (or any other request function) at any
time, even before the connection has been established - the API object
always waits until after login before it actually sends the requests, and
queues them until then.

Example: ping the porttracker server.

   $api->req ("ping", sub {
      my ($api, $ok, $timestamp, $pid) = @_;
      ...
   });

Example: determine the product ID.

   $api->req (product_id => sub {
      my ($api, $ok, $branding, $product_id) = @_;
      ...
   });

Example: set a new license.

   $api->req (set_license => $LICENSE_STRING, sub {
      my ($api, $ok) = @_;

      $ok or die "failed to set license";
   });

=cut

sub req {
   my $cb = pop;
   push @_, sub {
      splice @_, 1, 1
         or $_[0]->error ($_[1]);

      &$cb
   };

   $_[0]{queue}
      ? push @{ $_[0]{queue} }, [@_]
      : &_req
}

=item @res = $api->req_sync ($type => @args)

Similar to C<< ->req >>, but waits for the results of the request and on
success, returns the values instead (without the success flag, and only
the first value in scalar context). On failure, the method will C<croak>
with the error message.

=cut

sub req_sync {
   push @_, my $cv = AE::cv;
   &req;
   my ($ok, @res) = $cv->recv;

   $ok
      or Carp::croak $res[0];

   wantarray ? @res : $res[0]
}

=item $api->req_failok ($type => @args, $callback->($api, $success, @reply))

Just like C<< ->req >>, with two differences: first, a failure will not
raise an error, second, the initial status reply which indicates success
or failure is not removed before calling the callback.

=cut

sub req_failok {
   $_[0]{queue}
      ? push @{ $_[0]{queue} }, [@_]
      : &_req
}

=item $api->on (XYZ => $callback)

Overwrites any currently registered handler for C<on_XYZ> or
installs a new one. Or, when C<$callback> is undef, unregisters any
currently-registered handler.

Example: replace/set the handler for C<on_discover_stop_event>.

   $api->on (discover_stop_event => sub {
      my ($api, $gid) = @_;
      ...
   });

=cut

sub on {
   my $self = shift;

   while (@_) {
      my ($event, $cb) = splice @_, 0, 2;
      $event =~ s/^on_//;

      $self->{"on_$event"} = $cb;
   }
}

sub on_start_tls_notify {
   my ($self) = @_;

   $self->{hdl}->starttls (connect => $self->{tls_ctx});
   $self->{tls} ||= 1;

   $self->_login;
}

sub on_hello_notify {
   my ($self, $version, $auths, $nonce) = @_;

   $version == 1
      or return $self->error ("protocol mismatch, got $version, expected/supported 1");

   $nonce = MIME::Base64::decode_base64 $nonce;

   $self->{hello} = [$auths, $nonce];

   $self->_login
      unless $self->{tls}; # delay login when trying to handshake tls
}

sub _login_success {
   my ($self, $method) = @_;

   _req @$_
      for @{ delete $self->{queue} };

   call $self, on_login => $method;
}

sub _login {
   my ($self) = @_;

   my ($auths, $nonce) = @{ delete $self->{hello} or return };

   if (grep $_ eq "none", @$auths) {
      $self->_login_success ("none");

   } elsif (grep $_ eq "login_cram_md6", @$auths) {
      my $cc = join "", map chr 256 * rand, 0..63;

      my $key = Digest::HMAC_MD6::hmac_md6 $self->{pass}, $self->{user}, 64, 256;
      my $cr  = Digest::HMAC_MD6::hmac_md6_base64 $key, "$cc$nonce", 64, 256;
      my $sr  = Digest::HMAC_MD6::hmac_md6_base64 $key, "$nonce$cc", 64, 256;

      $cc = MIME::Base64::encode_base64 $cc;

      $self->_req (login_cram_md6 => $self->{user}, $cr, $cc, sub {
         my ($self, $ok, $msg) = @_;

         $ok
            or return call $self, on_login_failure => $msg;

         $msg eq $sr
            or return call $self, on_login_failure => "sr and cr mismatch, possible man in the middle attack";

         $self->_login_success ("login_cram_md6");
      });
   } elsif (grep $_ eq "login", @$auths) {
      $self->_req (login => $self->{user}, $self->{pass}, sub {
         my ($self, $ok, $msg) = @_;

         $ok
            or return call $self, on_login_failure => $msg;

         $self->_login_success ("login");
      });
   } else {
      call $self, on_login_failure => "no supported auth method (@$auths)";
   }

   # we no longer need these, make it a bit harder to get them
   delete $self->{user};
   delete $self->{pass};
}

sub on_info_notify {
   my ($self, $msg) = @_;

   warn $msg;
}

sub on_error_notify {
   my ($self, $msg) = @_;

   $self->error ($msg);
}

sub on_error {
   my ($self, $msg) = @_;

   warn $msg;

   %$self = ();
}

sub on_login_failure {
   my ($self, $msg) = @_;

   $msg =~ s/\n$//;
   $self->error ("login failed: $msg");
}

sub on_event_notify {
   my ($self, $event, @args) = @_;

   call $self, "on_${event}_event", @args;
}

=back

=head1 EVENTS/CALLBACKS

AnyEvent::Porttracker connections are fully event-driven, and naturally
there are a number of events that can occur. All these events have a name
starting with C<on_> (example: C<on_login_failure>).

Programs can catch these events in two ways: either by providing
constructor arguments with the event name as key and a code-ref as value:

   my $api = new AnyEvent::Porttracker
      host => ...,
      user => ..., pass => ...,
      on_error => sub {
         my ($api, $msg) = @_;
         warn $msg;
         exit 1;
      },
   ;

Or by sub-classing C<AnyEvent::Porttracker> and overriding methods of the
same name:

   package MyClass;

   use base AnyEvent::Porttracker;

   sub on_error {
      my ($api, $msg) = @_;
      warn $msg;
      exit 1;
   }

Event callbacks are not expected to return anything and are always passed
the API object as first argument. Some might have default implementations
(for example, C<on_error>), others are ignored unless overriden.

Description of individual events follow:

=over 4

=item on_error $api, $msg

Is called for every (fatal) error, including C<error> notifies. The
default prints the message and destroys the object, so it is highly
advisable to override this event.

=item on_login $api, $method

Called after a successful login, after which commands can be send. It is
permissible to send commands before a successful login: those will be
queued and sent just before this event is invoked. C<$method> is the auth
method that was used.

=item on_login_failure $api, $msg

Called when all login attempts have failed - the default raises a fatal
error with the error message from the server.

=item on_hello_notify $api, $version, $authtypes, $nonce

This protocol notification is used internally by AnyEvent::Porttracker -
you can override it, but the module will most likely not work.

=item on_info_notify $api, $msg

Called for informational messages from the server - the default
implementation calls C<warn> but otherwise ignores this notification.

=item on_error_notify $api, $msg

Called for fatal errors from the server - the default implementation calls
C<warn> and destroys the API object.

=item on_start_tls_notify $api

Called when the server wants to start TLS negotiation. This is used
internally and - while it is possible to override it - should not be
overridden.

=item on_event_notify $api, $eventname, @args

Called when the server broadcasts an event the API object is subscribed
to. The default implementation (which should not be overridden) simply
re-issues an "on_eventname_event" event with the @args.

=item on_XYZ_notify $api, ...

In general, any protocol notification will result in an event of the form
C<on_NOTIFICATION_notify>.

=item on_XYZ_event $api, ...

Called when the server broadcasts the named (XYZ) event.

=back

=head1 SEE ALSO

L<AnyEvent>, L<http://www.porttracker.com/>, L<http://www.infoblox.com/en/products/portiq.html>.

=head1 AUTHOR

 Marc Lehmann <marc@nethype.de>

=cut

1
