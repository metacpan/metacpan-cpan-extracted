#!/usr/bin/perl

##
# MyAgent.pl - a nice & easy example of an agent embedded in a perl
#  program.  Needs a Static agent to relocate to.
# Distributed with J. Duncan's permission.
# James Duncan <jduncan@hawk.igs.net>
# September, 1998.
##


BEGIN {
	unless ($ARGV[0]) {
		print 'Copyright 1998 James Duncan' . "\n";
		print 'Released under the GNU and Perl Artistic license';
		print "\n";
		print "Usage:\n\tMyAgent.pl <ipaddr:port>\n";
		print "\n";
		$die = 1;
	}
	eval { use Agent; };
	if ($@) { 
		print "The Agent module is missing from your system\n"; 
		$die = 1;
	}
}

exit(1) if $die;

my $code= <<'HERE';

package Agent::Example::Test;
@ISA = qw ( Agent );

sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = {};
	foreach (keys(%args)) { $self->{$_} = $args{$_}; }
	bless $self, $class;
}

sub agent_main {
	my $self = shift;
	my $to = delete ($self->{Host});
	my $mesg = new Agent::Message (
					Body => [
						ref($self)."\n", 
						$self->store()
					],
					Transport => TCP,
					Address => $to
				      );
	if ($to) {
		my $data = $mesg->send();
		if (!$data) { print "Odd, I couldn't send me.\n"; }
	} else {
		print "**** A Test from James ****\n";
	}
}

HERE

my $agent = new Agent ( Host => $ARGV[0],  Code => $code );
$agent->run();
