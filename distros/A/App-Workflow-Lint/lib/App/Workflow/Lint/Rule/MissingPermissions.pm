package App::Workflow::Lint::Rule::MissingPermissions;

use strict;
use warnings;
use Carp qw(croak carp);
use parent 'App::Workflow::Lint::Rule';

sub id          { 'missing-permissions' }
sub description { 'Workflow should define a top-level permissions block' }

#----------------------------------------------------------------------
# check($workflow, $ctx)
#
# Returns a diagnostic hashref if the workflow lacks a permissions block.
#----------------------------------------------------------------------
sub check {
    my ($self, $wf, $ctx) = @_;

    return () if exists $wf->{permissions};

    return {
        rule    => $self->id,
        level   => 'warning',
        message => 'Workflow is missing a top-level permissions block',
        path    => '/',
        file    => $ctx->{file},
    };
}

1;

