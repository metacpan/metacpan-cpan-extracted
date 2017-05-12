#!/usr/bin/perl   -w 
#!/usr/local/bin/perl -w  

## A testing resource server. 
# Usage ./resource.pl resource_port  resource_ip  socket_type
# You must respect the parameter order. If you need to pass a
# parameter, you *must* pass all parameters before it. The others ones
# are not mandatory. 

use IO::Socket; 
use threads; 
use diagnostics; 

use constant DEFAULT_RESOURCE_IP => "127.0.0.1"; 
use constant DEFAULT_RESOURCE_PORT => 3000; 
use constant SOCKET_TYPE => 'udp'; 

## Function to be threaded when some client connects. 
sub read_accepted { 
	my $new_sock = $_[0];
	my $x; 
	local $| = 1; # flush imediately STDOUT 
	while($new_sock){
		print $x  if ($new_sock 
				and $x = <$new_sock>); #if $new_sock: supressing warnings. 
		undef $new_sock if (not $x);
	}
}

## Main. 

my $socket_type =  ($ARGV[0] ? $ARGV[0] : SOCKET_TYPE);
my $our_port = ($ARGV[1] ? $ARGV[1] : DEFAULT_RESOURCE_PORT);
my $our_ip = ($ARGV[2] ? $ARGV[2] : DEFAULT_RESOURCE_IP);

print "We are $our_ip:$our_port listening $socket_type sockets.\n";

my $sock; 
if ($socket_type eq 'tcp'){
	$sock = new IO::Socket::INET ( 
		LocalPort 	=> $our_port, 
		Proto       => $socket_type,
		Listen		=> 1,
		Reuse		=> 1, 
	); 
}
else{
	$sock = new IO::Socket::INET ( 
		LocalPort 	=> $our_port, 
		Proto       => $socket_type,
	); 
}
die "testing server: problems creating socket.\n" unless $sock ; 

my $t = "";
my $new_sock; 
local $| = 1; # flush imediately STDOUT 
while ( 1 ) { 
	$sock->recv($t, 256); 
	print $t; 
	$new_sock = $sock->accept(); 
	my $thr = threads->new(\&read_accepted, $new_sock) if $new_sock;
}

close ($sock); 
