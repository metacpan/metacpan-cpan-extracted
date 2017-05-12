package CallOfDuty::LANMapper;

use 5.006;

use warnings;
use strict;

use IO::Select;
use IO::Socket::INET;


=head1 NAME

CallOfDuty::LANMapper - COD Server detection and query

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This modules lets you detect Call Of Duty servers on your lan and query them once you know their hostname and IP.
Currently only Call Of Duty 4 servers are supported.

    use CallOfDuty::LANMapper;
 
    my $servers = CallOfDuty::LANMapper::get_servers();
    foreach my $server ( @$servers )
    {
    	my $info = CallOfDuty::LANMapper::get_status($server);
    }

=head1 FUNCTIONS

=head2 get_servers

 my $servers = CallOfDuty::LANMapper::get_servers()

This function broadcasts on the local network looking for Call Of Duty servers.

An array reference containing host and port is returned e.g [ "gameserver:28960" ]

=cut

sub get_servers
{
	my $servers = [];

	foreach my $port ( 28960 , 28961 , 28962 )
	{
		socket(my $socket, AF_INET, SOCK_DGRAM, getprotobyname('udp'));
		setsockopt($socket, SOL_SOCKET, SO_BROADCAST, 1);
		my $destpaddr = sockaddr_in($port, INADDR_BROADCAST);
		send($socket, 'Q', 0, $destpaddr);
		my $wait = IO::Select->new($socket);
		while( my ($found) = $wait->can_read(1) ) 
		{
   			my $srcpaddr = recv($socket, my $data, 100, 0);
   			my ( $port , $ipaddr ) = sockaddr_in($srcpaddr);
			push( @$servers , gethostbyaddr($ipaddr, AF_INET) . ":" . $port );
		}
    		close $socket;
	}
	return $servers;
}


=head2 get_status

 my $servers = CallOfDuty::LANMapper::get_status( "localhost:28960" );

This function contacts the call of duty server passed in and queries it for its status.

A hash reference or undef for failure is returned. Of chief interest are the player_count field
which contains the number of players on the server , the player field which contains an array reference 
which contains the current players, mapname and sv_hostname.

=cut

sub get_status
{
	my ( $address  ) = @_;
	my $request = pack( "CCCC" , 255 , 255 , 255 , 255 ) . "getstatus xxx";
	
	my $response = generic_request( $address  ,  $request );
	if( !defined($response) ) 
	{
		return $response;
	}
	my @players = ();
	while( $response->{"mod"} =~ /"([^"]+)"/g )
	{
		push( @players , $1 );
	}
	$response->{"player_count"} = scalar(@players);
	$response->{"players"} = \@players;
	return $response;
}

#generic request sendig function
sub generic_request
{	
	my ( $address , $request ) = @_;
	my ( $host , $port ) = split( /:/ , $address );
	my $socket = IO::Socket::INET->new( LocalPort => $port , PeerPort => $port , Proto => 'udp' , PeerAddr => $host);
	unless($socket)
	{
		warn( "could not open socket - generic - $!" );
		return undef;
	}

	$socket->send($request);

	my $wait = IO::Select->new($socket);
	my $text;

	if( my ($found) = $wait->can_read(1) )
	{
		$socket->recv($text,1024);
	}
	else
	{
		return undef;
	}

	if(length($text) == 0 )
	{
		return undef;
	}
	$text =~ s/.*?\\//s;

	my $response = {};
	while( $text =~ /([^\\]+)\\([^\\]+)/g )
	{
		$response->{$1} = $2;
	}
	
	return $response;
}

=head1 AUTHOR

Peter Sinnott, C<< <link at redbrick.dcu.ie> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-callofduty-lanmapper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CallOfDuty-LANMapper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CallOfDuty::LANMapper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CallOfDuty-LANMapper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CallOfDuty-LANMapper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CallOfDuty-LANMapper>

=item * Search CPAN

L<http://search.cpan.org/dist/CallOfDuty-LANMapper>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Peter Sinnott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of CallOfDuty::LANMapper
