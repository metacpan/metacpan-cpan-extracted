package App::Workflow::Lint::Rule::MissingRunsOn;

use strict;
use warnings;
use Carp qw(croak carp);
use parent 'App::Workflow::Lint::Rule';

sub id          { 'missing-runs-on' }
sub description { 'Jobs must define runs-on' }
sub applies_to  { 'job' }
sub level       { 'error' }

sub check_job {
    my ($self, $job, $ctx) = @_;

    return () if exists $job->{'runs-on'};

    return $self->diag(
        message => "Job '$ctx->{job_name}' is missing runs-on",
        path    => "/jobs/$ctx->{job_name}",
        file    => $ctx->{file},
    );
}

1;

