package BrLock::SomePerlFunc;

use strict; 
use IO::Socket;
use base 'Exporter';
our @EXPORT = qw(choose_integer send_tcp_string send_udp_string);

# choose_integer(x):
#   returns a random integer between 0 and x. 
sub choose_integer {
	my $max_integer = $_[0];
	srand time; # not a really good seed, however...
	return int (rand $max_integer); 
	return $max_integer - 1; 
}

# send_udp_string(str, ip, port):
#   this function sends the string str as a udp message to the host
#   ip:port. 
#   Return values:
#   0 -> ok; the message was throw correctly (note we can never
#   ensure if a udp package has arrived)
#   1 -> error (probably with socket creation). 

sub send_udp_string {
	my ($str, $ip, $port) = @_; 
	my $sock = new IO::Socket::INET (
		PeerAddr    => $ip,
		PeerPort    => $port,
		Proto       => 'udp',
	);
	# return if cannot create a socket. 
	return  1  unless $sock ;
	# throw the package. 
	print $sock $str;
	close $sock; 
	return 0; 
}

# send_tcp_string(str, ip, port):
#   this function sends the string str as a tcp message to the host
#   ip:port. 
#   Return values:
#   0 -> ok; the message was sent correctly 
#   1 -> error (probably with socket creation). 

sub send_tcp_string {
	my ($str, $ip, $port) = @_; 
	my $sock = new IO::Socket::INET (
		PeerAddr    => $ip,
		PeerPort    => $port,
		Proto       => 'tcp',
		timeout     => 0,
	);
	# return if cannot create a socket. 
	return  1  unless $sock ;
	# throw the package. 
	print $sock $str;
	close $sock; 
	return 0; 
}

BEGIN{
}
return 1; 
