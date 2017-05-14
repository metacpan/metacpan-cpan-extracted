#!/usr/bin/perl

##
# A perl script that execute the example agents distributed with the
#  Agent Perl package.
# Steve Purkis <spurkis@engsoc.carleton.ca>
# May 3, 1998
##

use Agent;

$usage = <<USAGE;

Usage:
   perl ex.pl -n <AgentName> [-l <logfile>] [-s] [-t] [-v]
              [a1.b1.c1.d1:port1 [a2.b2.c2.d2:port2 ...]]

	-v = verbose mode
	-s = use a Safe compartment for each agent run [Static only]
	-t = use Thread.pm [if available. Static only]
	-l = redirect STDOUT to the logfile specified
	aN.bN.cN.dN:portN
	   = numeric ip address and port of remote agent to talk to,
	     or address to listen on if Static agent.

For example, this starts a Safe Static agent in quiet mode:

	perl ex.pl -n Static -s 192.168.0.53:24368

USAGE

# if you want to see lots of meaningless output :-), uncomment these:
$Agent::Message::Debug = 1;
$Agent::Transport::TCP::Debug = 1;
$Agent::Debug = 1;
#$Class::Tom::debug = 1;

# first, set up the arguments (maybe I should use GetOpt???):
my (%args, $logfile);
while ($arg = shift @ARGV) {
	if ($arg =~ /.+\:\d+/) {
		# safe to say it's an ip address
		push (@{$args{'Hosts'}}, $arg);
		# but HelloWorld agents can only handle 1 Host:
		$args{'Address'} = $arg;
		if (exists($args{'Host'})) {
			$args{'Return'} = $arg;
		} else {
			$args{'Host'} = $arg;
		}
		# and Loop agents like 'Tell' better...
		$args{'Tell'} = $arg;
	} elsif ($arg =~ /-v/i) {
		$args{'verbose'} = 1;
	} elsif ($arg =~ /-s/i) {
		$args{'Cpt'} = 1;
	} elsif ($arg =~ /-t/i) {
		$args{'Thread'} = 1;
	} elsif ($arg =~ /-l/i) {
		$logfile = shift @ARGV;
	} elsif ($arg =~ /-n/i) {
		$args{'Name'} = shift @ARGV;
	}
}
$args{Eval} = '2+2';
unless ($args{'Name'}) { print $usage; exit 1; }

if ($logfile) {
	open (LOG, "> $logfile") or die "couldn't open $logfile! $!";
	select LOG;
	$| = 1;
}

# then setup and execute the agent:
my $agent = new Agent( %args ) or die "couldn't create agent!";
my $results = eval { $agent->run; };
print "Error running agent: $@" if $@;
print "Results: $results\n" if $results;


__END__

=head2 EX.PL

A script to execute the example agents distributed with the I<Agent Perl>
package.
