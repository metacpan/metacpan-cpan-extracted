package TestMasonApp::InterpExecNoneTemplate;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{param} = "success";
    return $self->interp_exec;
}

1;

