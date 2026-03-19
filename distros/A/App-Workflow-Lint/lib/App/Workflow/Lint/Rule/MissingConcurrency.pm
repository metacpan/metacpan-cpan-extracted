package App::Workflow::Lint::Rule::MissingConcurrency;

use strict;
use warnings;
use Carp qw(croak carp);
use parent 'App::Workflow::Lint::Rule';

sub id          { 'missing-concurrency' }
sub description { 'Workflow should define a concurrency group' }
sub applies_to  { 'workflow' }
sub level       { 'info' }

sub check_workflow {
    my ($self, $wf, $ctx) = @_;

    return () if exists $wf->{concurrency};

    return $self->diag(
        message => "Workflow is missing a concurrency group",
        path    => '/',
        file    => $ctx->{file},
    );
}

1;

