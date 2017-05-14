#!/usr/bin/perl

##
# TCP[/IP] transport subclass for Agent Perl.
# Steve Purkis <spurkis@engsoc.carleton.ca>
# June 18, 1998
##

package Agent::Transport::TCP;
use vars qw( $Debug );

use IO::Socket;

@ISA = qw( Agent::Transport );

##
# Non-OO Stuff
##

sub send {
	my (%args) = @_;
	my $addr;

	$addr = valid_address($args{Address});

	unless ($addr = $args{Address}) {
		warn "No valid transport address defined: $args{Address}!";
		return;
	}
	my @msg = @{$args{Message}};

	# open a new socket & send the data
	my $con = new IO::Socket::INET(
		Proto => 'tcp',
		Timeout => 1,
                PeerAddr => $addr,
                Reuse => 1
	) or return ();	# use IO::Socket's $!

	for( @msg ) { $con->send( $_ ) or return (); }

	# preserve connection?
	${$args{KeepAlive}}  = $con if (ref $args{KeepAlive} eq 'SCALAR');

	$con->close();
	undef $con;	# paranoia
	1;
}

sub valid_address {
	$_ = shift;
	$_ =~ /(^(\d{1,3}\.){3}\d{1,3})|(^(\w+\.)*\w+)\:\d+$/;
	return $_;
}

##
# OO Stuff
##

sub new {
	my ($class, %args) = @_;
	my $self = {};
	my ($addr, $port);

	# set defaults:
	unless ($args{Address}) {
		$args{Address} = '127.0.0.1:24368';
		$args{Cycle} = 1;
	}

	unless (valid_address($args{Address})) {
		warn "Invalid transport address: $args{Address}!";
		return;
	}
	# split so we can cycle port # if need be...
	($addr, $port) = split(/:/, $args{Address});

	# open a new server socket:
	while (1) {
		last if $self->{Server} = new IO::Socket::INET(
			Proto => 'tcp',
			Listen => 1,
			LocalAddr => $addr . ':' . $port,
			Reuse => 1
		);
		print "Couldn't get connection: $!\n" if ($Debug && $!);
		return unless $args{'Cycle'};	# cycle for a free port?
		$port++;
	}

	$self->{Server}->autoflush();
	bless $self, $class;
}

sub recv {
	my ($self, %args) =  @_;

	my $remote = $self->accept(%args) or return ();

	return $remote->getlines();
}

sub accept {
	my ($self, %args) =  @_;

	$self->{Server}->timeout($args{Timeout}) if $args{Timeout};
	my $remote = $self->{Server}->accept() or return;
	$remote->autoflush();
	my $from = $remote->peerhost . ':' . $remote->peerport;
	print "Connection from $from\n" if $Debug;

	# does the caller want to keep the 'from' variable?
	${$args{From}} = $from if (ref $args{From} eq 'SCALAR');
	return $remote;
}

sub address {
	my ($self, %args) =  @_;
	# use socket calls to obtain info about our server socket
	return ($self->{Server}->sockhost . ':' . $self->{Server}->sockport);
}

sub aliases {
	my ($self, %args) =  @_;

	# use socket calls to get all hostnames for our server
	# cheat for now:
	return [ $self->address ];
}

sub transport {
	my ($self, %args) =  @_;
	return 'TCP';
}

1;


__END__

=head1 NAME

Agent::Transport - the Transportable Agent Perl module

=head1 SYNOPSIS

 use Agent::Transport;

 # for receiving messages:
 $tcp = new Agent::Transport(
 	Medium => 'TCP',
 	Address => '1.2.3.4:1234'
 );
 
 # for sending:
 use Agent::Message;
 
 $msg = new Agent::Message(
 	Medium => 'TCP',
 	Body => [ @body ],
 	Address => '1.2.3.4:1234'
 );
 $msg->send;

=head1 DESCRIPTION

This package provides an interface to the TCP[/IP] transport medium
for agent developers to make use of.

=head1 ADDRESS FORMAT

=over 3

=item This package groks the following standard tcp/ip formats:

 aaa.bbb.ccc.ddd:port
 host.domain:port

=back

=head1 CONSTRUCTOR

=over 4

=item new( %args )

If the I<Cycle> argument is passed and if new() cannot capture the port
specified, it will cycle through port numbers until a free port is found.
If C<new> is not passed an I<Address> at all, it assumes '127.0.0.1:24368',
and sets I<Cycle> to 1.

=back

=head1 METHODS & SUBS

This module contains all of the Agent::Transport standard methods.  Some
non-standard features have also been introduced:

=over 4

=item $self->accept( %args )

This method is analagous to the accept() function call and is introduced to
allow agent programmers to make full use of bi-directional sockets.  It
simply opens an incoming connection and returns that object, thus allowing
you to use a single connection for multiple messages (see C<IO::Socket> for
details).  Unfortunately, you'll have to design your own protocol.

Passing a 'From' argument as a referenced scalar, causes accept() to put
I<what it thinks> the remote address is into this variable.

=item $self->alias()

Returns $self->address() only.  It should really do hostname lookups.

=item $self->recv( %args )

Passing a 'From' argument as a referenced scalar, causes recv() to put
I<what it thinks> the remote address is into this variable.  Otherwise,
recv() functions as described in I<Agent::Transport>.

=item send( %args )

If you pass send() a 'KeepAlive' argument containing a I<reference> to a
scalar, it will set this scalar to the remote I<socket filehandle>.  This is
meant to be used in conjunction with accept(), and is useful if you would
like to have an extended conversation with the remote host.

=back

=head1 NOTES

This module only binds to a specified address.  If you have multiple
interface addresses (ie: eth0 & eth1), and you want to listen on more than
one, you have to bind each seperately.

=head1 SEE ALSO

C<Agent> C<Agent::Transport>

=head1 AUTHOR

Steve Purkis E<lt>F<spurkis@engsoc.carleton.ca>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Steve Purkis. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 THANKS

Various people from the perl5-agents mailing list.

=cut
v