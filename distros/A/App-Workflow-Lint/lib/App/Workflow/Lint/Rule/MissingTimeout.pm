package App::Workflow::Lint::Rule::MissingTimeout;

use strict;
use warnings;
use Carp qw(croak carp);

# Inherit the DSL from the base rule class
use parent 'App::Workflow::Lint::Rule';

#----------------------------------------------------------------------
# Metadata
#----------------------------------------------------------------------

sub id		  { 'missing-timeout' }
sub description { 'Jobs should define timeout-minutes' }
sub applies_to  { 'job' }
sub level	   { 'warning' }

#----------------------------------------------------------------------
# Rule logic
#----------------------------------------------------------------------

sub check_job {
	my ($self, $job, $ctx) = @_;

	# If the job already has a timeout, nothing to report
	return () if exists $job->{'timeout-minutes'};

	# Otherwise return a diagnostic
	return $self->diag(
		message => "Job '$ctx->{job_name}' is missing timeout-minutes",
		path	=> "/jobs/$ctx->{job_name}",
		file	=> $ctx->{file},
		fix	 => sub {
			my ($wf) = @_;
			$wf->{jobs}{$ctx->{job_name}}{'timeout-minutes'} = 10;
		},
	);
}

1;

