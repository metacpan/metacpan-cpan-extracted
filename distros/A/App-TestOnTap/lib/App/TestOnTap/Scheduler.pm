package App::TestOnTap::Scheduler;

use strict;
use warnings;

our $VERSION = '1.001';
my $version = $VERSION;
$VERSION = eval $VERSION;

use TAP::Parser::Scheduler::Job;
use TAP::Parser::Scheduler::Spinner;

# This acts like a TAP Scheduler, but uses the test dispenser
# to give out jobs.
# This happens according to eligibility after continually
# toposorting and removing completed jobs, making
# it possible to parallelize tests efficiently
#
sub new
{
	my $class = shift;
	my $dispenser = shift;
	my @testPairs = @_;

	# create 
	#
	my $self = bless
				(
					{
						pez => $dispenser,
						jobs => undef,
						queue => undef,
						finished => [],
						spinner => TAP::Parser::Scheduler::Spinner->new()
					},
					$class
				);

	# create a list of job objects which is what
	# the harness wants
	# also hook them up to a closure to be called when they finish
	#	
	my %jobs;
	foreach my $pair (@testPairs)
	{
		my $job = TAP::Parser::Scheduler::Job->new(@$pair);
		$job->on_finish( sub { $self->__finish(@_) } );
		$jobs{$job->description()} = $job;
	}
	$self->{jobs} = \%jobs;
	
	return $self;
}

# list of all remaining tests (jobs)
#
sub get_all
{
	my $self = shift;

	return values(%{$self->{jobs}});	
}

# return the next eligible job
#  - if all jobs completed, return undef
#  - if no job is currently eligible (due to dependencies etc), return a 'spinner' job
#
sub get_job
{
	my $self = shift;

	# maintain a queue of eligible tests here since we should deliver just one job
	# at a time but the dispenser may 'free up' multiple at a time
	#
	if (!$self->{queue} || ($self->{queue} && !@{$self->{queue}}))
	{
		# if there is no queue right now (first call after creation)
		# or the queue is empty, attempt to retrieve a new queue from the
		# dispenser. The dispenser is called with the current list of finished
		# jobs, so it may recompute and see what, if anything, is now free to run
		#
		$self->{queue} = $self->{pez}->getEligibleTests($self->{finished});
		$self->{finished} = [];
	}
	
	# the dispenser will return undef when there are no more tests, which means we
	# will return undef too
	#  
	my $job;
	if ($self->{queue})
	{
		if (@{$self->{queue}})
		{
			# if there are tests in the queue, pop the first
			# and translate it to a job object
			#
			my $t = shift(@{$self->{queue}});
			$job = $self->{jobs}->{$t};
		}
		else
		{
			# the queue is empty but still active, so spin our wheels a bit... 
			#
			$job = $self->{spinner}; 
		}
	}

	return $job;
}

sub __finish
{
	my $self = shift;
	my $job = shift;
	
	my $t = $job->description();
	push(@{$self->{finished}}, $t);
	delete($self->{jobs}->{$t});
}

1;
