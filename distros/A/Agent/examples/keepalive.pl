#!/usr/bin/perl

##
# Keepalive.pl - demonstrates sustained connections with TCP transport.
# Steve Purkis <spurkis@engsoc.carleton.ca>
# October 24, 1998
##

use Agent;

# I know we're not an agent, but this is just a demo. ;-)

# get a TCP transport address:
my $tcp = new Agent::Transport(
	Medium => 'TCP',
	Cycle => 1,
	Address => '127.0.0.1:24368'
) or die "Couldn't get a tcp transport address: $!!\n";
$addr = $tcp->address();
print "Got tcp address $addr.\n";

unless ($pid=fork()) {
	# child
	print "forked. parent is $$.\n";
	my $serv;
	sleep 1;	# give time for server to setup...
        my $con = new IO::Socket::INET(
                Proto => 'tcp',
                Timeout => 10,
                PeerAddr => $addr,
                Reuse => 1
        ) or die "C: Ack! $!";
	$con->autoflush();

	print "C: made it! ", ref( $con ), "\n";
	print $con "Hello There!\n";
	print "C: ", <$con>, "finished printing, exiting.\n";;
	exit 0;
}
# parent

print "forked.  child is $pid.\n";
print "S: waiting for incoming...\n";
my $client = $tcp->accept() or die "ACK!";

my @data = $client->getline;

print "S: made it! ", ref( $client ), "\n";
print @data;
print "S: writing 'hi there!\\n' to C...\n";
print $client "hi there! Ed!\n";
print "S: done.\n";
undef $client;	# terminate socket connection

"Waiting for process $pid...\n";
waitpid( $pid, 0 );
