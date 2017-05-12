package App::Diskd;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.01';

use POE;

sub Daemon {

  print "Starting diskd in daemon mode\n";

  my $info = Local::Info->new;

  my $blkid_session = Local::DiskWatcher->new(info => $info,);
  my $usock_session = Local::UnixSocketServer->new(info => $info);
  my $multi_session = Local::MulticastServer->new(info => $info, ttl=>2);

  POE::Kernel->run();

}

sub Client {

  print "Starting diskd in client mode\n";

  my $usock_client = Local::UnixSocketClient->new;

  POE::Kernel->run();
}

1;

##
## The Info package is intended to provide a central area where we can
## store details of known disks and hosts. It just provides some
## useful get/set interfaces that the other packages can use.
##

package Local::Info;

use POE qw(Wheel::Run);

use Sys::Hostname;
use Net::Nslookup;

sub new {
  my $class = shift;

  my $hostname = hostname;
  my ($ip) = nslookup $hostname;

  return bless {
		this_host      => $hostname,
		this_ip        => $ip,
		temp_disk_list => [],
		disks_by_ip    => { $ip => {} },
		update_time    => {},
	       }, $class;
}

sub our_ip { (shift)->{this_ip} }

# We update local disk info in two phases, first creating a list to
# store them, then inserting the list into the live data all at once.
# This is so that we can handle disks being detached from the system
# between runs of blkid.

sub add_our_disk_info {

  my ($self,$uuid,$label,$device) = @_;

  my $listref = $self->{temp_disk_list};

  # As a mnemonic for the order below, remember that UUIDs are more
  # unique than labels, which in turn are more unique than device
  # filenames.
  push @$listref, [$uuid,$label,$device];

}

sub commit_our_disk_info {

  my $self = shift;
  my $ip = $self->{this_ip};

  #warn "comitting new blkid data with " . (0+ @{$self->{temp_disk_list}}) .
  #  " entries\n";

  $self->{update_time}->{$ip} = time();
  $self->{disks_by_ip}->{$ip} = $self->{temp_disk_list};
  $self->{temp_disk_list}     = [];

  # TODO: update "last seen" structures for each disk with a label/uuid.
  # for each structure, map the label/uuid to [ip, timestamp] info.
}

sub known_hosts {
  my $self = shift;
  return keys %{$self->{disks_by_ip}};
}
sub disks_by_host {
  my ($self,$host) = @_;

  #warn "looking up host $host";
  return undef unless exists $self->{disks_by_ip}->{$host};
  return $self->{disks_by_ip}->{$host};
}

#
# The routines used to pack and unpack a list of disks for
# transmission could take any form, really. The key things to consider
# are that (a) arbitrary spoofed data can't result in us introducing
# security issues (so solutions that involve eval'ing the packed data
# are out, unless we validate that the data is in the expected form)
# and (b) we take into consideration quoting issues (such as not using
# spaces as separators, since they may appear in disk labels). As it
# happens, YAML can solve both of these problems for us. It may not
# make best use of space, but at least it's quick and easy to
# implement.
#

use YAML::XS;

# assume that we don't need to pack any disk list except our own
sub pack_our_disk_list {
  my $self = shift;
  my $ip = $self->{this_ip};

  return Dump $self->{disks_by_ip}->{$ip};
}

# unpack incoming list of lists
sub unpack_disk_list {
  my ($self,$host,$yaml) = @_;
  my $ip = $self->{this_ip};

  # We shouldn't get here if the calling routine is doing its job right
  if ($host eq $ip) {
    warn "Fatal: caller requested unpack disk list with our IP address";
    return undef;
  }

  my $objref = Load $yaml;

  # Do some basic type checking on the unpacked object. We expect an
  # array of arrays.
  unless (ref($objref) eq "ARRAY") {
    warn "unpacked disk list is not an ARRAY";
    return undef;

    for (@$objref) {
      unless (ref($_) eq "ARRAY") {
	warn "unpacked disk element is not an ARRAY";
	return undef;
      }
    }
  }

  $self->{update_time}->{$host} = time();

  return $self->{disks_by_ip}->{$host} = $objref;
}

#
# The remaining packages are used simply to achieve a clean separation
# between different POE sessions and to encapsulate related methods
# without having to worry about namespace issues (like ensuring event
# names and handler routines are unique across all sessions). As a
# consequence of having distinct sessions for each program area, when
# we need to have inter-session communication, we need to use POE's
# post method. An alias is also used to identify each of the sessions.
#


##
## The DiskWatcher package sets up a session to periodically run
## blkid, parse the results and store them in our Info object. Since
## blkid can sometimes hang (due to expected devices or media not
## being present), a timer is set and if the command hasn't completed
## within that timeout, the child process is killed and the child
## session garbage collected.
##

package Local::DiskWatcher;

use POE qw(Wheel::Run Filter::Line);

sub new {

  my $class = shift;
  my %args = (
	      program   => '/sbin/blkid',
	      frequency => 10 * 60 * 1, # seconds between runs
	      timeout   => 15,
	      info      => undef,
	      @_
	     );

  die "DiskWatcher needs info => ref argument\n" unless defined($args{info});

  # by using package_states, POE event names will eq package methods
  my @events =
    qw(
	_start start_child child_timeout got_child_stdout got_child_stderr
	child_cleanup
     );
  my $session = POE::Session->create
    (
     package_states => [$class => \@events],
     args => [%args],
    );

  return bless { session => $session }, $class;
}


# Our _start event is solely concerned with extracting args and saving
# them in the heap. It then queues start_child to run the actual child
# process and timeout watcher.
sub _start {

  #print "DiskWatcher: _start args: ". (join ", ", @_). "\n";

  my ($kernel, $heap, %args) = @_[KERNEL, HEAP, ARG0 .. $#_];

  $heap->{timeout} = $args{timeout};
  $heap->{info}    = $args{info};
  $heap->{program} = $args{program};
  $heap->{delay}   = $args{frequency};
  $heap->{child}   = undef;

  $kernel->yield('start_child');
}

# start_child is responsible for running the program with a timeout
sub start_child {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Using a named timer for timeouts. Set it to undef to deactivate.
  $kernel->delay(child_timeout => $heap->{timeout});

  $heap->{child} = POE::Wheel::Run->new(
    Program      => [$heap->{program}],
    StdioFilter  => POE::Filter::Line->new(),
    StderrFilter => POE::Filter::Line->new(),
    StdoutEvent  => "got_child_stdout",
    StderrEvent  => "got_child_stderr",
    CloseEvent   => "child_cleanup",
  );
  $kernel->sig_child($heap->{child}->PID, "child_cleanup");

  # queue up the next run of this event
  $kernel->delay(start_child => $heap->{delay});
}

# if the child process didn't complete within the timeout, we kill it
sub child_timeout {
  my ($heap) = $_[HEAP];
  my $child  = $heap->{child};

  warn "CHILD KILL TIMEOUT";
  warn "diskid failed to send kill signal\n" unless $child->kill();

  # The kernel should eventually receive a SIGCHLD after this
}

# For our purposes, we don't care whether the child exited by closing
# its output or throwing a SIGCHLD. Wrap the deletion of references to
# the child in if(defined()) to avoid warnings.
sub child_cleanup {

  #print "DiskWatcher: child_cleanup args: ". (join ", ", @_). "\n";

  my ($heap,$kernel) = @_[HEAP,KERNEL];

  # Deactivate the kill timer
  $kernel->delay(child_timeout => undef);

  # We need to commit the new list of disks and recycle the child
  # object. Both of these should only be called once, even if this
  # routine is called twice.
  if (defined($heap->{child})) {
    my $info = $heap->{info};
    $info->commit_our_disk_info;

    delete $heap->{child};
  }
}

# Consume a single line of output (thanks to using POE::Filter::Line)
sub got_child_stdout {
  my ($heap,$_) = @_[HEAP,ARG0];

  my ($uuid,$label,$device) = ();

  $uuid   = $1 if /UUID=\"([^\"]+)/;
  $label  = $1 if /LABEL=\"([^\"]+)/;
  $device = $1 if /^(.*?):/;

  return unless defined($device); # we'll silently fail if blkid
                                  # output format is not as expected.
  return unless defined($label) or defined($uuid);

  my $info = $heap->{info};

  # the call to add_our_disk_info just queues the update, then when we
  # clean up this child, we'll instruct info to "commit" the update.
  # This is needed to take care of removing old disks that are no
  # longer attached.
  $info->add_our_disk_info($uuid,$label,$device);

  #  print "STDOUT: $_\n";
}

# Echo any stderr from the child
sub got_child_stderr {
  my ($heap,$stderr,$wheel) = @_[HEAP, ARG0, ARG1];
  my $child = $heap->{child};
  my $pid   = $child->PID;
  warn "blkid $pid> $stderr\n";
}

##
## The MountWatcher package will be responsible for periodically
## running mount to determine which of the known disks are actually
## mounted. It will follow pretty much the same approach as for the
## DiskWatcher package.
##

package Local::MountWatcher;

use POE qw(Wheel::Run);



##
## The MulticastServer package handles connection to a multicast group
## and sending and receving messages across it.
##

package Local::MulticastServer;

use POE;
use IO::Socket::Multicast;

use constant DATAGRAM_MAXLEN   => 1500;
use constant MCAST_PORT        => 32003;
use constant MCAST_GROUP       => '230.1.2.3';
use constant MCAST_DESTINATION => MCAST_GROUP . ':' . MCAST_PORT;

sub new {

  my $class = shift;
  my %opts = (
	      initial_delay => 5,
	      frequency => 10 * 60,
	      info => undef,
	      ttl => 1,		# set >1 to traverse routers
	      @_
	     );

  die "UnixSocketServer::new requires info => \$var option\n"
    unless defined($opts{info});

  my $session =
    POE::Session->create(
	inline_states => {
	       	   _start         => \&peer_start,
	       	   get_datagram   => \&peer_read,
	       	   send_something => \&send_something,
	       	  },
	heap => {
		 initial_delay => $opts{initial_delay},
		 frequency     => $opts{frequency},
		 info          => $opts{info},
		 ttl           => $opts{ttl},
		},
    );

  return bless { session => $session }, $class;
}

# Set up the peer socket.

sub peer_start {
  my ($kernel,$heap) = @_[KERNEL, HEAP];

  # Don't specify an address.
  my $socket = IO::Socket::Multicast->new(
    LocalPort => MCAST_PORT,
    ReuseAddr => 1,
    #ReusePort => 1,
  ) or die $!;

  $socket->mcast_ttl($heap->{ttl});

  $socket->mcast_add(MCAST_GROUP) or die $!;

  # Don't mcast_loopback(0).  This disables multicast datagram
  # delivery to all peers on the interface.  Nobody gets data.

  # Begin watching for multicast datagrams.
  $kernel->select_read($socket, "get_datagram");

  # Save socket in the heap
  $heap->{socket} = $socket;

  # delay sending the first packet to give DiskWatcher a chance to complete
  $kernel->delay(send_something => $heap->{initial_delay});

  # Send something once a second.  Pass the socket as a continuation.
  #   $kernel->delay(send_something => $heap->{frequency}, $socket);
}

# Receive a datagram when our socket sees it.

sub peer_read {
  my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];
  my $info = $heap->{info};

  my $remote = recv($socket, my $message = "", DATAGRAM_MAXLEN, 0);

  if (defined $remote) {

    my ($peer_port, $peer_addr) = unpack_sockaddr_in($remote);
    my $ip = inet_ntoa($peer_addr);

    if ($message =~ s/^diskd://) {
      #print "Valid datagram received from $ip : $peer_port ... $message\n";
      $info->unpack_disk_list($ip, $message) unless $ip eq $info->our_ip;
    } else {
      warn "Unexpected/malformed packet from $ip:$peer_port ... $message\n";
    }

  } else {

    warn "multicast recv error (ignored) $!\n";
  }
}

# Periodically send the list of disks

sub send_something {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $info = $heap->{info};
  my $socket = $heap->{socket};
  my $delay = $heap->{frequency};

  #  my $message = "pid $$ sending at " . time() . " to " . MCAST_DESTINATION;
  my $message = "diskd:" . $info->pack_our_disk_list;

  warn $! unless $socket->mcast_send($message, MCAST_DESTINATION);

  $kernel->delay(send_something => $delay);
}


##
## The UnixSocketServer package uses a Unix domain socket to provide a
## local ineterface to the disk info and a means of sending commands
## or messages to other nodes in our multicast network.
##
## This package comprises a main server package (UnixSocketServer)
## that waits for connections to the socket, and and a package that's
## spawned for each incoming connection (UnixSocketServer::Session).
##

package Local::UnixSocketServer;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite);
use Socket;          # For PF_UNIX.

# Start server at a particular rendezvous (ie, Unix domain socket)
sub new {
  my $class   = shift;
  my $homedir = $ENV{HOME};
  my %opts    =
    (
     rendezvous => "$homedir/.diskd-socket",
     info       => undef,
     @_,
    );

  # warn "class: $class; opts: " . (join ", ", @_);

  die "UnixSocketServer::new requires info => \$var option\n"
    unless defined($opts{info});

  POE::Session->create(
    inline_states => {
      _start     => \&server_started,
      got_client => \&server_accepted,
      got_error  => \&server_error,
    },
    heap => {
      rendezvous => $opts{rendezvous},
      info       => $opts{info}
    },
  );
}

# The server session has started.  Create a socket factory that
# listens for UNIX socket connections and returns connected sockets.
# This unlinks the rendezvous socket
sub server_started {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  unlink $heap->{rendezvous} if -e $heap->{rendezvous};
  $heap->{server} = POE::Wheel::SocketFactory->new(
    SocketDomain => PF_UNIX,
    BindAddress  => $heap->{rendezvous},
    SuccessEvent => 'got_client',
    FailureEvent => 'got_error',
  );
}

# The server encountered an error while setting up or perhaps while
# accepting a connection.  Register the error and shut down the server
# socket.  This will not end the program until all clients have
# disconnected, but it will prevent the server from receiving new
# connections.
sub server_error {
  my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
  $error = "Normal client disconnection." unless $errno;
  warn "Server socket encountered $syscall error $errno: $error\n";
  delete $heap->{server};
}

# The server accepted a connection.  Start another session to process
# data on it.
sub server_accepted {
  my ($heap,$client_socket) = @_[HEAP, ARG0];
  my $info = $heap->{info};
  Local::UnixSocketServer::Session->new($client_socket, $info);
}

## A UnixSocketServer::Session instance is created for each incoming
## connection.

package Local::UnixSocketServer::Session;

use POE::Session;

# Constructor
sub new {
  my ($class,$socket,$info) = @_;
  #warn "new $class: $socket, $info";
  POE::Session->create(
    package_states => [ $class => [qw( _start session_input session_error)] ],
    args => [$info, $socket],
  );
}

# The server session has started.  Wrap the socket it's been given in
# a ReadWrite wheel.  ReadWrite handles the tedious task of performing
# buffered reading and writing on an unbuffered socket.
sub _start {
  my ($heap, $info, $socket) = @_[HEAP, ARG0, ARG1];
  $heap->{client} = POE::Wheel::ReadWrite->new(
    Handle     => $socket,
    InputEvent => 'session_input',
    ErrorEvent => 'session_error',
#    InputEvent => 'got_client_input',
#    ErrorEvent => 'got_client_error',
  );
  $heap->{info}=$info;
  $heap->{client}->put("diskd local interface awaiting commands\n");
}

# The server session received some input from its attached client.
# Echo it back.
sub session_input {
  my ($heap, $_) = @_[HEAP, ARG0];
  my $info = $heap->{info};

  chomp;

  if (/^help\b/i) {
    $heap->{client}->put
      ("Available commands:\n" .
       "list                 show disk info\n" .
       "where <label|uuid>   show last known location of disk\n" .
       "localhost            report local hostname, IP address\n" .
       "status               show network statistics\n" .
       "debug                start monitoring notable events\n" .
       "quit|exit            exit client" # handled client-side
      );
  } elsif (/^list\b/i) {

    my $output = '';
    foreach my $host ($info->known_hosts) {
      #warn "Got host $host";
      foreach my $listref (@{$info->disks_by_host($host)}) {
	# Perl lets us use hash slices as well as array slices
	my ($uuid, $label, $device) = @$listref;
	$uuid   = '' unless defined $uuid;
	$label  = '' unless defined $label;
	$device = '' unless defined $device;

	$output.= sprintf("%-15s %-37s %-10s %s\n",
			  "$host:",$uuid,$label,$device);
      }
    }
    $heap->{client}->put($output);

  } elsif (/^where\b/i) {
    if (/^where\b\s+(\S+)/i) {

    } else {
      $heap->{client}->put("'where' requires a disk label or uuid\n");
    }
  } elsif (/^localhost\b/i) {

  } elsif (/^status\b/i) {

  } elsif (/^debug\b/i) {

  } else {
    $heap->{client}->put("unknown command: $_\n");
  }
}

# The server session received an error from the client socket.  Log
# the error and shut down this session.  The main server remains
# untouched by this.
sub session_error {
  my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
  $error = "Normal disconnection." unless $errno;
  warn "Server session encountered $syscall error $errno: $error\n";
  delete $heap->{client};
}


package Local::UnixSocketClient;

# This program is a simple unix socket client.  It will connect to the
# UNIX socket specified by $rendezvous.  This program is written to
# work with the UnixServer example in POE's cookbook.  While it
# touches upon several POE modules, it is not meant to be an
# exhaustive example of them.  Please consult "perldoc [module]" for
# more details.

use Socket qw(AF_UNIX);
use POE;                          # For base features.
use POE::Wheel::SocketFactory;    # To create sockets.
use POE::Wheel::ReadWrite;        # To read/write lines with sockets.
use POE::Wheel::ReadLine;         # To read/write lines on the console.

# Specify a UNIX rendezvous to use.  This is the location the client
# will connect to, and it should correspond to the location a server
# is listening to.
our $rendezvous;

sub new {
  my $class   = shift;
  my $homedir = $ENV{HOME};
  my %opts    =
    (
     rendezvous => "$homedir/.diskd-socket",
     @_,
    );

  $rendezvous = $opts{rendezvous};

  # Create the session that will pass information between the console
  # and the server.  The create() constructor maps a number of events
  # to the functions that will be called to handle them.  For example,
  # the "sock_connected" event will cause the socket_connected()
  # function to be called.
  POE::Session->create(
    inline_states => {
      _start         => \&client_init,
      sock_connected => \&socket_connected,
      sock_error     => \&socket_error,
      sock_input     => \&socket_input,
      cli_input      => \&console_input,
    },
  );
}

# The client_init() function is called when POE sends a "_start" event
# to the session.  This happens automatically whenever a session is
# created, and its purpose is to notify your code when it can begin
# doing things.
# Here we create the SocketFactory that will connect a socket to the
# server.  The socket factory is tightly associated with its session,
# so it is kept in the session's private storage space (its "heap").
# The socket factory is configured to emit two events: On a successful
# connection, it sends a "sock_connected" event containing the new
# socket.  On a failure, it sends "sock_error" along with information
# about the problem.
sub client_init {
  my $heap = $_[HEAP];
  $heap->{connect_wheel} = POE::Wheel::SocketFactory->new(
    SocketDomain  => AF_UNIX,
    RemoteAddress => $rendezvous,
    SuccessEvent  => 'sock_connected',
    FailureEvent  => 'sock_error',
  );
}

# socket_connected() is called when the session receives a
# "sock_connected" event.  That event is generated by the session's
# SocketFactory object when it has connected to a server.  The newly
# connected socket is passed in ARG0.
# This function discards the SocketFactory object since its purpose
# has been fulfilled.  It then creates two new objects: a ReadWrite
# wheel to talk with the socket, and a ReadLine wheel to talk with the
# console.  POE::Wheel::ReadLine was named after Term::ReadLine, by
# the way.  Once socket_connected() has set us up the wheels, it calls
# ReadLine's get() method to prompt the user for input.
sub socket_connected {
  my ($heap, $socket) = @_[HEAP, ARG0];
  delete $heap->{connect_wheel};
  $heap->{io_wheel} = POE::Wheel::ReadWrite->new(
    Handle     => $socket,
    InputEvent => 'sock_input',
    ErrorEvent => 'sock_error',
  );
  $heap->{cli_wheel} = POE::Wheel::ReadLine->new(InputEvent => 'cli_input');
  $heap->{cli_wheel}->get("=> ");
}

# socket_input() is called to handle "sock_input" events.  These
# events are provided by the POE::Wheel::ReadWrite object that was
# created in socket_connected().
# socket_input() moves information from the socket to the console.
sub socket_input {
  my ($heap, $input) = @_[HEAP, ARG0];
  $heap->{cli_wheel}->put("$input");
}

# socket_error() is called to handle "sock_error" events.  These
# events can come from two places: The SocketFactory will send it if a
# connection fails, and the ReadWrite object will send it if a read or
# write error occurs.
# The most common way to handle I/O errors is to shut down the sockets
# having problems.  Here we'll delete all our wheels so the program
# can shut down gracefully.
# ARG0 contains the name of the syscall that failed.  It is often
# "connect" or "bind" or "read" or "write".  ARG1 and ARG2 contain the
# numeric and descriptive contents of $! at the time of the failure.
sub socket_error {
  my ($heap, $syscall, $errno, $error) = @_[HEAP, ARG0 .. ARG2];
  $error = "Normal disconnection." unless $errno;
  warn "Client socket encountered $syscall error $errno: $error";
  delete $heap->{connect_wheel};
  delete $heap->{io_wheel};
  delete $heap->{cli_wheel};
}

# Finally, the console_input() function is called to handle
# "cli_input" events.  These events are created when
# POE::Wheel::ReadLine (created in socket_connected()) receives user
# input from the console.
# Plain input is registered with ReadLine's input history, echoed back
# to the console, and sent to the server.  Exceptions, such as when
# the user presses Ctrl+C to interrupt the program, are also handled.
# POE::Wheel::ReadLine events include two parameters other than the
# usual KERNEL, HEAP, etc.  The ARG0 parameter contains plain input.
# If that's undefined, then ARG1 will contain an exception.
sub console_input {
  my ($heap, $input, $exception) = @_[HEAP, ARG0, ARG1];
  if (defined $input) {
    $heap->{cli_wheel}->addhistory($input);
    #    $heap->{cli_wheel}->put("You Said: $input");
    $heap->{io_wheel}->put($input);
  }
  elsif ($exception eq 'cancel') {
    $heap->{cli_wheel}->put("Canceled.");
  }
  else {
    $heap->{cli_wheel}->put("Bye.");
    delete $heap->{cli_wheel};
    delete $heap->{io_wheel};
    return;
  }

  # Prompt for the next bit of input.
  $heap->{cli_wheel}->get("=> ");
}

1;

__END__


=head1 NAME

diskd - An example POE-based, peer-to-peer disk finder/announcer

=head1 SYNOPSIS

  $ ./diskd -d &		# run in network daemon mode
  $ ./diskd			# start local client
  => help			# get help
  => list			# show information about known disks
  => ...
  => <EOF>			# ^D exits client

=head1 DESCRIPTION

This program is intended as an example of:

=over

=item 1. using multicast to send and receive data among several peers

=item 2. communicating with local clients via a Unix domain socket

=item 3. using POE to achieve both of the above

=item 4. using POE to periodically run an external program without blocking

=item 5. encapsulating a data structure that can be accessed and updated by the above

=back

The information shared between peers in this example is the list of
disks that are currently attached to each system. The "blkid" program
is used to gather this information. It reports on all disks attached,
regardless of whether the disk (or partition) is currently mounted or
not.

A copy of diskd should be run on each of the peer machines. The first
thing that it does is join a pre-defined multicast channel. The daemon
then collects the list of disks attached to the system and schedules
the collection to trigger again periodically. It also sets up a
periodic event that will send the details of the disks attached to the
machine to other peers that have joined the multicast channel. It also
listens to the channel for incoming multicast messages from another
peer and uses them to update its list of which disks are attached to
that peer. As a result of this, each daemon will be able to build up a
full list of which disks are available in the peer network and to
which machine they are attached. Thus the primary function of the
program is to be able to locate disks, no matter which machine they
are currently attached to.

The diskd program can also be run in client mode on any machine that
has a running diskd daemon. The client conencts via a local unix
domain socket and, providing the connection succeeds, it will then be
able to pass commands to the daemon. Currently the only useful command
that is implemented is 'list', which prints a list of all the disks
that the daemon knows about. More commands could be added quite
easily.

=head1 MOTIVATION/GENESIS

The reason for writing this program was to explore three key areas:

=over

=item 1. Multicast (and peer-to-peer) networking

=item 2. Daemons and method of communicating with them

=item 3. Using POE to develop a non-trivial program with a focus on asynchronous, event-based operation

=back

As I write this, the size of the program is significantly less than
1,000 lines (not including this documentation), while still managing
to implement a reasonably complex network daemon. In all, it took
about an evening's work to code and eliminate most of the major
bugs. The reason for both the small size and quick development time
can be attributed to the combination of Perl and POE. Despite this
being my first time writing any program using POE, the speed of
development was not down to amazing programming skill on my
part. Rather, it boiled down to just one factor: almost all of the POE
code I have here was based, in one way or another, on example code
hosted on the L<POE Cookbook site|http://poe.perl.org/?POE_Cookbook>.

Since I had already read up sufficiently on POE (and the examples in
the cookbook) and knew in general how I wanted my daemon to work,
selecting the relevant recipes and reworking them was a pretty
straightforward process. Based on this experience, I would definitely
recommend other Perl programmers to consider POE for programs of this
sort (network daemons) as well as for any other task where the an
event-based approach is suitable.


=head1 POINTS OF INTEREST

From the outset, I had decided that I would modularise the code and
use different objects (classes) for each functional part of the
overall program. Besides being a reasonable approach in general, it
also turned out that this was a good practical fit with the POE way of
doing things since I could use a separate POE session for each
class. Using separate classes meant that, for example, I could have
the same event name across several different sessions/classes without
needing to worry about whether they would interfere with each
other. This was a boon considering that most of my POE code started as
cut and paste from other examples.

For the remainder of this section, I would like to simply go through
each of the classes used in the program and give some brief notes. I
have attempted to comment the code to make it easier to read and
understand, but the notes here give some extra context and extra
levels of detail.

=head2 Info class

This class simply encapsulates the data structures that are collected
locally and shared among nodes. A distinction is made between the two
so that calling classes have a convenient interface for updating only
local data (eg, DiskWatcher), or querying globally-shared data (eg, a
client running a 'list' command).

The Info class does not have an associated POE session, though a
reference to the Info object is passed to every class/POE session that
needs to access/update it. So even though it doesn't use POE itself,
it is basically the glue that holds all the POE sessions together and
gives them meaning.

The current implementation simply keeps all the data in memory, though
it would be simple enough to either:

=over

=item * provide a routine to be called at program startup to read in saved data from a file or other backing storage (along with a complementary routine to save the data when the program is shutting down); or

=item * interface with a database to act as a permanent storage medium (POE provides mechanisms for doing this asynchronously, which might be appropriate here)

=back

Internally, this class also uses YAML to pack and unpack (serialise
and deserialise) the stored data. This is used by the MulticastServer
class to safely transmit and receive data within the UDP packets. It
could also be used to load/save the data to local storage between
program runs (ie, provide persistence of data).


=head2 DiskWatcher class

This class sets up a POE session that periodically calls the external
'blkid' program. It uses POE::Wheel::Run to do this in the background
so that the parent program does not block while waiting on the child
program to run to completion.

In some cases, blkid can hang (such as if a device has disappeared
without being cleanly unmounted or disconnected) or fail altogether
(such as the user not having sufficient rights, or the program not
being present on the system). This class handles both cases
gracefully.

=head2 MountWatcher class

This is not implemented, but the idea is that in addition to peers
announcing and tracking which disks are attached to which machines,
they would also share information about which of those disks are
currently mounted.

A simple implementation would simply call the system 'mount' command
in a similar way that 'blkid' is called in the DiskWatcher class.

If implemented, it might also make sense (subject to security
considerations) to allow clients to issue commands to mount (and
possibly unmount) selected disks. This would make it easier for other
applications to search for a disk and, if it is found, issue the
command for the machine to which the disk is attached to mount it
before the remote host tries to mount it (with something like nfs or
sshfs, for example). The point here would be to provide a relatively
location-independent way of doing remote mounts.

=head2 MulticastServer class

This class is responsible for sending and receiving packets to and
from a specific multicast channel. It begins by joining the multicast
channel and then sets up:

=over

=item * a listener which receives updates from other peers; and

=item * a periodic event that sends information about locally-attached disks to all peers

=back

All packets are sent using UDP, so there is no acknowledgement
process. Because packets are sent using multicast, a single packet
should find its way to all members of the multicast group.

A "ttl" ("time to live") option is provided so that if peers are on
different subnets, a multicast-aware router can forward the packets to
any subnet that has a subscribed peer. I have tested this and
confirmed that it works, at least for peers separated by a single
router hop. Simply set the value to (maximum number of hops + 1).

The MulticastServer object relies on the Info object to provide
(de-)serialisation of the data. The way this is currently implemented
(using YAML and some extra checking on the received data structure),
this prevents the possibility of a rogue peer joining the network and
sending data packets that are specially crafted so as to allow them to
execute arbitrary Perl code (ie, receiving arbitrary data should not
present a security risk). The question of whether I<broadcasting>
(multicasting) information about what disks are attached represents a
security risk is left to the user to decide.

=head2 UnixSocketServer and UnixSocketServer::Session classes

Using standard OO terminology, the UnixSocketServer class is a
"Factory" that creates UnixSocketServer::Session objects. The
"Factory" class listens for new connections on a private Unix-domain
socket (basically, a file in the user's home directory that only that
user can access, which acts like a local socket). When a new
connection comes in, it creates a new UnixSocketServer::Session
object. Multiple connections can be created, with a new Session object
created for each one.

Once it is up and running, a UnixSocketServer::Session object then
reponds to commands like "help", "list" and so on that come through
the socket.

A simple enough extension of the current program would be implement a
command (in UnixSocketServer::Session) that causes the daemon to
multicast the current list of locally-attached disks to all peers,
regardless of the current timeout value. Similar commands could cause
the daemon to trigger the DiskWatcher or MountWatcher classes to
refresh their data.

A slightly more complicated extension would be a "ping"-like
command. The Session object would recognise it and then send out a
message to all peers requesting that they send their list of local
disks again. In order to prevent this from being abused (eg, a rogue
peer on the network using it to flood the network with traffic and
cause a Denial of Service attack), you might want to implement some
form of rate limiting in the MulticastServer class: basically, it
would limit the number of "ping" requests it would send answers to, so
that any excess ping requests in a given time period would be ignored.

=head2 UnixSocketClient class

This class is the counterpart to the UnixSocketServer and
UnixSocketServer::Session classes. It takes commands typed in by the
user, sends them to the server and displays the output.

This client incorporates ReadLine support (for editing of command
lines, as well as a history buffer) and graceful shutdown (on the
client side at least---the server side must close the Session down
based on seeing that the client side has closed the socket
connection).

It should be noted that this class is, strictly speaking, not
necessary. By passing the correct parameters to the "telnet" program,
it should be possible to communicate with the local daemon
directly. However, telnet does not generally have ReadLine support,
whereas this class does. Given the size of the class (150 lines,
including copious comments) and the fact that it can be adapted to
connect to many different kinds of server, it does seem to be worth
including here.

=head1 SEE ALSO

(insert links here)

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Declan Malone

This program is free software; you can redistribute it and/or modify
it under the terms of version 2 (or, at your discretion, any later
version) of the "GNU General Public License" ("GPL").

Please refer to L<http://www.gnu.org/licenses/gpl.html> for the full
text of this license.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

