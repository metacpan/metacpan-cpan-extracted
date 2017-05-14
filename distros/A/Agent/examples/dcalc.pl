#!/usr/bin/perl

##
# This demonstrates a simple disctributed calculation program that
# uses perl agents.  See 'README' file for copyright information.
# Steve Purkis <spurkis@engsoc.carleton.ca>
# October 5, 1998
##


use Agent;

$usage = <<USAGE;

Usage:
   perl dcalc.pl [-v] [-t] serv:port host1:port [host2:port ...]

	-v = verbose mode
	-t = use threads
	hostN:port = ip:port of remote hosts (ie: Static agents)
	serv:port  = server address to bind to

USAGE

# if you want to see lots of meaningless output :-), uncomment these:
#$Agent::Transport::TCP::Debug = 1;
#$Agent::Debug = 1;
#$Class::Tom::debug = 2;

# first, set up the arguments:
my (%args, %hosts);
while (my $arg = shift @ARGV) {
	if ($arg =~ /.+\:\d+/) {
		# safe to say it's an ip address
		if ($args{Return}) { $hosts{$arg} = ''; }
		else               { $args{Return} = $arg; }
	} elsif ($arg =~ /-v/i) {
		$args{'verbose'} = 1;
	} elsif ($arg =~ /-t/i) {
		$args{'Thread'} = 1;
	}
}
unless ((keys(%hosts)) > 0) { print $usage; exit 1; }
print "starting distributed calculation agent system.\n";


# get a TCP transport address:
my $tcp = new Agent::Transport(
	Medium => 'TCP',
	Address => $args{Return}
) or die "Couldn't get a tcp transport address: $!!\n";
$args{Return} = $tcp->address();
print "Got tcp address $args{Return}.\n" if $args{verbose};


print "dispatching Eval agents...\n";
$args{Name} = 'Eval';
foreach $host (keys(%hosts)) {
	$args{Host} = $host;

	# set up the calulation to be done:
	$args{Eval} = "return ('$host=' . rand(10));";

	# and send the agent:
	my $agent = new Agent(%args) or die "couldn't create agent! $!";
	$agent->run();
	print "\t$host calculating '$args{Eval}'\n" if $args{verbose};
}

my $i = 1;
WHILE: while (1) {
	print "Waiting for response #$i...\n";
	my $rmt;
	my @msg = $tcp->recv( Timeout => 120, From => \$rmt) or die "Timeout reached!\n";
	print "Connection from: $rmt\n"  if $args{verbose};
	unless (@msg) {
		warn "No data in message!\n";
		next;
	}
	$i++;
	($key, $val) = split (/=/, @msg[0]);  # result should be in 1st line
	print "setting $key => $val\n" if $args{verbose};
	$hosts{$key} = $val;
	foreach (keys(%hosts)) {
		next WHILE if ($hosts{$_} eq '');
	}
	last;	# break while when all %hosts elements filled
}

print "Return values:\n";
foreach (keys(%hosts)) {
	print "\t$_ => $hosts{$_}\n";
	$result += $hosts{$_};
}
print "Sum: $result\n";
