package Asterisk::CoroManager;

require 5.8.8;

use strict;
use warnings;
use warnings::register;
use utf8;

use Coro;
use Coro::AnyEvent;                # NB: I have only tested with Coro::EV
use Coro::Semaphore;
use Coro::Channel;
use Coro::Debug;

use Carp qw( croak longmess );
use IO::Socket;
use Digest::MD5;
use Data::Dumper::Simple;
use Time::HiRes qw ( time );

use constant DEFAULT_TIMEOUT => 3; # Default timeout to wait for
                                   # action response

=head1 NAME

Asterisk::CoroManager - Asterisk Manager Interface, Coro version

=head1 SYNOPSIS

  use Asterisk::CoroManager;

  my $astman = new Asterisk::CoroManager({
                                          user   => 'username',
                                          secret => 'test',
                                          host   => 'localhost',
                                        });

  $astman->connect || die "Could not connect to " . $astman->host . "!\n";

  my $ping = $astman->sendcommand({ Action => 'Ping' }, { timeout => '2' });

  if( $ping ) {
      # $ping->{Response} should be 'Pong'
      print "Yay, we're alive! We got ". $ping->{Response} ."\n";
  }
  else {
      print "Got no pong in 2 seconds :-(\n";
  }

  $astman->disconnect;

=head1 DESCRIPTION

This module provides a dependable, event-based interface to the
asterisk manager interface.
L<http://www.voip-info.org/wiki/view/Asterisk+manager+API>

This is done with L<Coro>, and continuations.  If you are unfamiliar
with L<Coro>, go read up on it!  Your program should 'use Coro' quite
at the beginning, and be aware of that it is asynchronous.  If you
wait for an answer to a sendcommand, other events will probably be
triggered in the meanwhile.

=head2 Logging / Error handling

Asterisk::CoroManager uses L<Log::Log4perl> if it is installed.  Read
L<Log::Log4perl>, or initialize a simple logger like this:

  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init( { level => $DEBUG,
                              file => ">>test.log" } );

=cut

BEGIN {
    # Check for Log::Log4perl...
    eval { use Log::Log4perl qw(get_logger :nowarn); };
    if($@) {
	print "Log::Log4perl not installed - stubbing.\n";
	no strict qw(refs);
	*{__PACKAGE__."::$_"} = sub { } for qw(trace debug error fatal);
    }
    else {
	print "Log::Log4perl installed - logging enabled.\n";
	no strict qw(refs);
	foreach my $level (qw(trace debug error fatal)) {
	    *{__PACKAGE__."::$level"} =
	      sub {
		  $Log::Log4perl::caller_depth++;
		  my( $astman, $message ) = @_;
		  my $log = Log::Log4perl->get_logger();
		  $log->$level($astman->host .': '. $message);
		  $Log::Log4perl::caller_depth--;
		  return;
	      };
	}
    }
}


my $EOL = "\015\012";
my $BLANK = $EOL x 2;

use vars qw($VERSION); $VERSION = '0.11'; sub version { return $VERSION }

my $ACTIONID_SEQ = 1;
my $RESULT_SEQ = 1;



##############################################################################
##############################################################################

=head1 Constructor

=head2 new

  my $astman = new Asterisk::CoroManager({
                                          host   => 'localhost',
                                          user   => 'username',
                                          secret => 'test',
                                         });

Supported args are:

  host       Asterisk host.  Defaults to 'localhost'.
  port       Manager port.  Defaults to 5038,
  user       Manager user.
  secret     Manager secret.

=cut

sub new
{
    my( $class, $args ) = @_;

    my $astman;
    $astman =  bless {
		      host        => $args->{host} || 'localhost',
		      port        => $args->{port} || 5038,
		      user        => $args->{user},
		      secret      => $args->{secret},
		      watcher     => undef,
		      finished    => undef, # Will hold AnyEvent->condvar
		      action_cb   => {},    # Action response callbacks
		      event_cb    => {},    # event callbacks
		      event_dcb   => undef, # event default callback
		      uevent_cb   => {},    # userevent callbacks
		      uevent_dcb  => undef, # userevent default callback
		      ami_version => undef,
		      read_buffer => [],
		     }, __PACKAGE__;

    $astman->add_event_callback('UserEvent',
                                sub{ $astman->handle_uevent(@_) }
                               );

    return $astman;
}


##############################################################################
##############################################################################

=head1 Actions

=cut

##############################################################################

=head2 connect

  $astman->connect or croak "Could not connect to ". $astman->host ."!\n";

Connects the manager to asterisk.  User, secret and host should be set
before calling this.

Returns Asterisk Manager Interface version on success; otherwise undef.

=cut

sub connect
{
    my( $astman ) = @_;

    my $host = $astman->{host};
    my $port = $astman->{port};
    my $user = $astman->{user};
    my $secret = $astman->{secret};

    my $fh = new IO::Socket::INET( Proto => 'tcp',
				   PeerAddr => $host,
				   PeerPort => $port,
				   Blocking => 0,
				 );

    if (!$fh) {
	$astman->error("Can't bind ($host:$port): $@\n");
	return;
    }

    $astman->{fh} = $fh;
    $fh->autoflush(1);

    # Recieve greeting from asterisk server
    my $greeting = AnyEvent->condvar;
    my $greeting_watcher
      = AnyEvent->io( fh   => $fh,
                      poll => 'r',
                      cb   => sub { $greeting->send },
                    );

    # Waits for response
    $greeting->recv;
    my $input = <$fh>;
    $input =~ s/$EOL//g;
    $astman->trace("Greeting recieved: $input");
    my ($manager, $version) = split('/', $input);
    undef $greeting_watcher;

    # Check version
    if ($manager !~ /Asterisk Call Manager/) {
	return $astman->error("Unknown Protocol\n");
    }
    $astman->{ami_version} = $version;

    # Prepare normal recieving watcher-event
    $astman->{watcher}
      = AnyEvent->io( fh   => $fh,
                      poll => 'r',
                      cb   => sub { $astman->read_incoming( $fh ) },
                    );
    $astman->{finished} = AnyEvent->condvar;

    # Check if the remote host supports MD5 Challenge authentication
    my $authresp = $astman->sendcommand({
                                         Action   => 'Challenge',
                                         AuthType => 'MD5',
                                        });

    if ($authresp->{Response} eq 'Success') {
	# Do md5 login
	my $md5 = new Digest::MD5;
	$md5->add($authresp->{Challenge});
	$md5->add($secret);
	my $digest = $md5->hexdigest;
	my $resp = $astman->sendcommand({
                                         Action => 'Login',
                                         AuthType => 'MD5',
                                         Username => $user,
                                         Key => $digest,
                                        });
	$astman->debug("Login(MD5) response: ". Dumper($resp));
	unless( $resp->{Response} eq 'Success' ) {
	    $astman->fatal("Login failed.");
	    return;
	}
    }
    else {
	# Do plain text login
	my $resp = $astman->sendcommand({
				       Action => 'Login',
				       Username => $user,
				       Secret => $secret
				      });
	$astman->debug("Login(plain) response: ". Dumper($resp));
	unless( $resp->{Response} eq 'Success' ) {
	    $astman->fatal("Login failed.");
	    return;
	}
    }

    # Add watcher for restart, to reconnect after 3 seconds
    $astman->add_event_callback('Shutdown',
                                sub{ sleep 3;
                                     $astman->{fh}->close;
                                     $astman->check_connection;
                                 }
                               );

    # Check connection every 5th second..
    $astman->{clock_check}
      = AnyEvent->timer( after    => 5,
                         interval => 5,
                         cb       => sub {
                             async{ $astman->check_connection }
                         },
                       );

    return $version;
}


##############################################################################

=head2 disconnect

  $astman->disconnect;

Disconnects from asterisk manager interface and ends eventloop.

=cut

sub disconnect
{
    my ($astman) = @_;
    $astman->{finished}->send;
    return;
}


##############################################################################

=head2 sendcommand

  my $resp = $astman->sendcommand({
                                   Action    => 'QueuePause',
                                   Interface => 'SIP/1234',
                                   Paused    => 'true',
                                  },
                                  { Timeout => 2 });

Sends a command to asterisk.

If you are looking for a response, the command will wait for the
specific response from asterisk (identified with an ActionID).
Otherwise it returns immediately.

TODO: Implement timeout: Timeout is how long to wait for the response.
Defaults to 3 seconds.

Returns a hash or hash-ref on success (depending on wantarray), undef
on timeout.

=cut

sub sendcommand {
    my( $astman, $command, $args ) = @_;
    my $actionid = $command->{ActionID} || $ACTIONID_SEQ++;

    # Ping must be handled specially, since it doesn't return ActionID
    if( $command->{Action} and
	$command->{Action} eq 'Ping' ) {
	$actionid = 'Ping';
    }

    $command->{ActionID} ||= $actionid;

    $astman->trace("Sending command: ". Dumper($command));

    my $fh = $astman->{fh};
    my $cstring = make_packet(%$command);

    eval { # Send command to Asterisk
	$fh->send("$cstring$EOL");
    } or $astman->check_connection;

    if (defined wantarray) {
	$astman->debug("Waiting for response of command here.");
	$astman->trace(longmess());
	$astman->trace("-------------------------------------");
	$args ||= {};
	my $timeout = $args->{Timeout} || DEFAULT_TIMEOUT;
	my $response = new Coro::Channel;
	$astman->{action_cb}{$actionid} = sub{ $response->put(@_) };

	my $resp = $response->get; # Cede's until a response is gotten
	return unless( $resp );
	return wantarray ? %{$resp} : $resp;
	# TODO: Timeout!
    }

    return;
}


##############################################################################

=head2 check_connection

  $astman->check_connection();

Checks if the connection is still alive.  Tries to reconnect if it
isn't.

=cut

sub check_connection {
    my( $astman ) = @_;

    if( $astman->connected ) {
	$astman->debug("...connection appears to be fine...");
    }
    else {
	$astman->error("Lost connection to server!");
	$astman->error("Trying to reconnect...");

	$astman->{fh}->close if $astman->{fh}->connected;
	undef $astman->{fh};

	if( $astman->connect ) {
	    $astman->error("Succeeded in reconnect!  "
                           ."Continuing as if nothing happened.");
	}
	else {
	    $astman->fatal("Couldn't reconnect.  "
                           ."Dying here.  Good bye cruel world.");
	    croak "Couldn't reconnect.  Dying here.  "
              ."Good bye cruel world.";
	}
    }

    return;
}


##############################################################################

=head2 eventloop

  $astman->eventloop();

Will wait for events, until shut down.

=cut

sub eventloop {
    my ($astman) = @_;

    # Coro debug shell, if socket is available
    eval {
        my $shell = new_unix_server Coro::Debug "/tmp/myshell";
    };
    if($@) {
	$astman->error("Coro debug shell failed.\n");
    }

    $astman->{finished}->recv;

    return;
}


##############################################################################
##############################################################################

=head1 Accessors

=cut

##############################################################################

=head2 user

  $astman->user('user')

Set user for manager connection.

=cut

sub user {
    my ($astman, $user) = @_;

    if ($user) {
	$astman->{user} = $user;
    }

    return $astman->{user};
}


##############################################################################

=head2 secret

  $astman->secret('secret')

Set secret for manager connection.

=cut

sub secret {
    my ($astman, $secret) = @_;

    if ($secret) {
	$astman->{secret} = $secret;
    }

    return $astman->{secret};
}


##############################################################################

=head2 host

  $astman->host('localhost')

Set host for manager connection.

=cut

sub host {
    my ($astman, $host) = @_;

    if ($host) {
	$astman->{host} = $host;
    }

    return $astman->{host};
}


##############################################################################

=head2 port

  $astman->port(5038)

Set port for manager connection; defaults to 5038.

=cut

sub port {
    my ($astman, $port) = @_;

    if ($port) {
	$astman->{port} = $port;
    }

    return $astman->{port};
}


##############################################################################

=head2 connected

  croak "Not connected!" unless($astman->connected($timeout))

Checks if manager is connected (for timeout seconds).

Returns 1 if conencted, 0 if not.

=cut

sub connected {
    my ($astman, $timeout) = @_;

    return ($astman->{fh}->connected and
	    $astman->sendcommand({ Action => 'Ping' },
				 { Timeout => $timeout || DEFAULT_TIMEOUT })
           );
}


##############################################################################
##############################################################################

=head2 add_event_callback

  $astman->add_event_callback('Join', \&update_queue_status)

Add a callback for a specific event.

Returns 1 on success, 0 on error.

=cut

sub add_event_callback {
    my ($astman, $event, $function) = @_;

    if (defined($function) && ref($function) eq 'CODE') {
	$astman->{event_cb}{$event} = []
	  unless $astman->{event_cb}{$event};
	push @{$astman->{event_cb}{$event}}, $function;
    }
    else
    {
	$astman->error("add_event_callback called without CODE ref.");
	return 0;
    }

    return 1;
}


##############################################################################

=head2 add_default_event_callback

  $astman->add_default_event_callback(\&debug_events)

Add a callback for all events that don't have an callback set.

Returns 1 on success, undef on error.

=cut

sub add_default_event_callback {
    my ($astman, $function) = @_;

    if (defined($function) && ref($function) eq 'CODE') {
	$astman->{event_dcb} = []
	  unless $astman->{event_dcb};
	push @{$astman->{event_dcb}}, $function;
    }
    else
    {
	$astman->error("add_default_event_callback called without "
                       ."CODE ref."
                      );
	return;
    }

    return 1;
}


##############################################################################

=head2 add_uevent_callback

  $astman->add_uevent_callback('MyUserEvent', \&myfunction)

Add a callback for a specific user event.

Returns 1 on success, undef on error.

=cut

sub add_uevent_callback {
    my ($astman, $event, $function) = @_;

    if (defined($function) && ref($function) eq 'CODE') {
	$astman->{uevent_cb}{$event} = []
	  unless $astman->{uevent_cb}{$event};
	push @{$astman->{uevent_cb}{$event}}, $function;
    }
    else
    {
	$astman->error("add_uevent_callback called without CODE ref.");
	return;
    }

    return 1;
}


##############################################################################

=head2 add_default_uevent_callback

  $astman->add_default_uevent_callback(\&debug_events)

Add a callback for all user events that don't have an callback set.

Returns 1 on success, undef on error.

=cut

sub add_default_uevent_callback {
    my ($astman, $function) = @_;

    if (defined($function) && ref($function) eq 'CODE') {
	$astman->{uevent_dcb} = []
	  unless $astman->{uevent_cb};
	push @{$astman->{uevent_dcb}}, $function;
    }
    else
    {
	$astman->error("add_default_uevent_callback called without "
                       ."CODE ref."
                      );
	return;
    }

    return 1;
}


##############################################################################
##############################################################################

=head1 Private methods & functions

=cut

##############################################################################

=head2 read_incoming

Called for incoming data on fh.  Calls handle_packet on complete
packets.

=cut

sub read_incoming {
    my( $astman, $fh ) = @_;

    while (<$fh>) {
	my $line = $_;
	$line =~ s/$EOL//g;
	utf8::decode($line);

	if ($line eq '') {
	    my @packet = @{$astman->{read_buffer}};
	    async {
		$astman->handle_packet( \@packet );
	    };
	    $astman->{read_buffer} = [];
	}
	else {
	    push @{$astman->{read_buffer}}, $line;
	}
    }

    return;
}


##############################################################################

=head2 handle_packet

handle_packet is called when incoming on fh has gotten a full packet.

=cut

sub handle_packet {
    my( $astman, $packet ) = @_;
    my $pack = parse_packet( $packet );
    my $event = $pack->{Event};
    my $callback;

    if( $pack->{Ping} and
	not $pack->{ActionID}
      ) {
	$pack->{ActionID} = 'Ping';
    }

    if( $event ) {
	$astman->handle_event( $pack );
    }
    elsif( my $actionid = $pack->{ActionID} ) {
	$astman->debug("Returning response for Action $actionid");
	$astman->handle_actionresponse( $pack );
    }
    else {
	$astman->trace("Unhandled packet from Asterisk.");
    }

    return;
}


##############################################################################

=head2 handle_event

handle_event is called if an incoming packet is an event.  Falls back
to default event handler.

=cut

sub handle_event {
    my( $astman, $pack ) = @_;
    my $event = $pack->{Event};

    if ( my $callbacks =
	 $astman->{event_cb}{$event} ||
	 $astman->{event_dcb}
       ) {
	$astman->debug("Handling event: $event");
	foreach my $cb (@$callbacks) {
	    &{$cb}($pack);
	}
    }
    else {
	$astman->trace("Unhandled event: $event");
    }
    return;
}


##############################################################################

=head2 handle_uevent

handle_uevent is called if an incoming packet is a user event.  Falls
back to default user event handler and ultimately to default event
handler.

=cut

sub handle_uevent {
    my( $astman, $pack ) = @_;
    my $uevent = $pack->{UserEvent};

    if ( my $callbacks =
	 $astman->{uevent_cb}{$uevent} ||
	 $astman->{uevent_dcb} ||
	 $astman->{event_dcb}
       ) {
	$astman->debug("Handling uevent: $uevent");

	foreach my $cb (@$callbacks) {
	    &{$cb}($pack);
	}
    }
    else {
	$astman->trace("Unhandled uevent: $uevent");
    }
    return;
}


##############################################################################

=head2 handle_actionresponse

handle_actionresponse is called if an incoming packet is a response
with an ActionID.

=cut

sub handle_actionresponse {
    my( $astman, $resp ) = @_;
    my $actionid = $resp->{'ActionID'};

    if( my $callback = $astman->{action_cb}{$actionid} ) {
	&{$callback}($resp);
	delete $astman->{action_cb}{$actionid};
    }
    else {
	$astman->debug("Unhandled ActionID: $actionid");
	$astman->trace("Actions: ". Dumper( $astman->{action_cb} ));
    }
    return;
}


##############################################################################

=head2 parse_packet

Parses a packet as array-ref and returns it as hash-ref.

Puts unmatched lines in an array in $pack->{RestResult}.

=cut

sub parse_packet {
    my( $packet ) = @_;
    my @rest;
    my %pack;

    while (my $line = shift @{$packet}) {
	if( $line =~ /^([^:]+):\ {0,1}([^\ ].*)$/ ) {
	    $pack{$1} = $2;
	}
	else {
	    push @rest, $line;
	}
    }

    if( @rest ) {
	$pack{RestResult} = \@rest;
    }

    return \%pack;
}


##############################################################################

=head2 make_packet

Converting a hash-ref to packet-string for manager connection.

=cut

sub make_packet {
    my (%thash) = @_;

    my $tstring = '';

    if( $thash{ActionID} ) { # ActionID must be first
	$tstring .= 'ActionID: ' . $thash{ActionID} . ${EOL};
    }
    foreach my $key (keys %thash) {
	next if $key eq 'ActionID';
	$tstring .= $key . ': ' . $thash{$key} . ${EOL};
    }

    return $tstring;
}


##############################################################################


1;
