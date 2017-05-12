package Apache::Backend::POE::Connection;

use warnings;
use strict;

use Apache::Backend::POE::Message;
use IO::Socket::INET;
use POSIX qw(:errno_h);
use Carp qw(croak);
use bytes;
use Storable qw(nfreeze thaw);

sub new {
	my $class = shift;
	return bless({
		@_, # can be a hash
	}, $class);
}

sub connect {
 	my ($obj, $poe, $host, $port) = @_;

	my $self = bless({%{$obj}},ref($obj));
	$self->{parent} = $poe;
	$self->{service_name} = $self->{alias} || 'backend-';

	if ($host && $port) {
		$self->{host} = $host;
		$self->{port} = $port;
	}

	unless ($self->{host} && $self->{port}) {
		croak "Must pass host and port to connect or initial new";
	}

	# connect

	$self->{socket} = IO::Socket::INET->new(
		PeerAddr => $self->{host},
		PeerPort => $self->{port},
	) or do {
		#croak "Couldn't connect to $self->{host} : $self->{port} - $!";
		print STDERR "$$ Apache::Backend::POE:Connection Couldn't connect to $self->{host} : $self->{port} - $!\n";
		return undef;
	};
	
	binmode($self->{socket});
	#$self->{socket}->autoflush(1); # default
	$self->{socket}->blocking(0);

	$self->{buffer} = "";
	$self->{read_length} = undef;

	# register

	$self->msg_send($self->msg({
        cmd => "register_service",
        svc_name => $self->{service_name}.$$,
	}));
	#$self->msg_read(5);

	return $self;
}

sub msg {
	my $self = shift;
	return Apache::Backend::POE::Message->new(@_);
}

sub ping {
	my $self = shift;
	my $start = time();
#	my $no_pong = 1;
	
	$self->msg_send($self->msg({
			cmd => 'ping',
			time => time(),
	}));
    my $prefix = "$$ Apache::Backend::POE:Connection ";

	print STDERR "$prefix going to msg_read in ping()\n" if $Apache::Backend::POE::DEBUG > 1;
	my $msg = $self->msg_read(10);
	print STDERR "$prefix back from msg_read in ping()\n" if $Apache::Backend::POE::DEBUG > 1;
	
	unless (ref($msg)) {
		print STDERR "$prefix received a non reference\n" if $Apache::Backend::POE::DEBUG;
		return -1;
	}
	
	if ($Apache::Backend::POE::DEBUG) {
#		print STDERR "$prefix got a ".ref($msg)." package with no event()\n",return -99 unless ($msg->can('event'));
	}
	
	my $function = $msg->event();
#	print STDERR "$prefix function: $function\n";
	if ($Apache::Backend::POE::DEBUG) {
		print STDERR "$prefix no function in message\n" unless defined $function;
	}
	return 1 if (defined $function && $function eq 'pong');
  
	print STDERR "$prefix WRONG function received: $function\n" if $Apache::Backend::POE::DEBUG;
	
	return 0;
}

sub disconnect {
	my $self = shift;
	close($self->{socket}) if ($self->{socket});
	$self->{socket} = undef;
}

sub msg_read {
	my $self = shift;
	my $timeout = shift || undef;

	# no timeout blocks indef!
#    my $prefix = "$$ Apache::Backend::POE:Connection ";

	my $st = time();
	$st += $timeout if defined($timeout);
	
#	print STDERR "$prefix going into while block in msg_read()\n" if $Apache::Backend::POE::DEBUG > 1;
	while (1) {
		if (defined $self->{read_length}) {
#			print STDERR "$prefix looking for msg in buffer...\n" if $Apache::Backend::POE::DEBUG > 1;
			if (length($self->{buffer}) >= $self->{read_length}) {
				my $message = thaw(substr($self->{buffer}, 0, $self->{read_length}, ""));
				$self->{read_length} = undef;
				$message->{recv_time} = time();
				return $message;
			}
		} elsif ($self->{buffer} =~ s/^(\d+)\0//) {
			$self->{read_length} = $1;
#			print STDERR "$prefix got read length: $1\n" if $Apache::Backend::POE::DEBUG > 1;
			next;
		}
	
		#print STDERR "$prefix going to sysread\n" if $Apache::Backend::POE::DEBUG > 1;
		my $rv = sysread($self->{socket}, $self->{buffer}, 4096, length($self->{buffer}));
		if (!defined($rv) && $! == EAGAIN) {
#			print STDERR "$prefix sysread was going to block\n" if $Apache::Backend::POE::DEBUG > 1;
			# was going to block
			#return if (defined($timeout) && $st > time());
		}
		# read $rv bytes from socket
#		print STDERR "$prefix read $rv bytes\n" if $Apache::Backend::POE::DEBUG > 1 && defined $rv;
		
		if (defined($timeout)){
			return if time() > $st;
		}
	}

}

sub msg_send {
	my $self = shift;
	my $message = shift;
    my $prefix = "$$ Apache::Backend::POE:Connection ";
	
	print STDERR "$prefix socket is not connected\n" if $Apache::Backend::POE::DEBUG && !defined($self->{socket});
	
	$message->{send_time} = time();
	my $streamable = nfreeze($message);

	$streamable = length($streamable).chr(0).$streamable;
	my $len = length($streamable);
	print STDERR "$prefix sending $len bytes\n" if $Apache::Backend::POE::DEBUG > 1;
	while ($len > 0) {
		if (my $w = syswrite($self->{socket},$streamable,4096)) {
			$len -= $w;
			print STDERR "$prefix sent $w bytes\n" if $Apache::Backend::POE::DEBUG > 1;
		} else {
			last;
		}
	}
	print STDERR "$prefix done sending\n" if $Apache::Backend::POE::DEBUG > 1;
	#print *{$self->{socket}} $streamable;
}

sub msg_oneshot {
	my ($obj, $host, $port, $message) = @_;

	my $self = $obj->connect(undef, $host, $port);

	my $msg = $self->msg($message);
	
	$self->msg_send($msg);

	$self->disconnect();
}

1;
