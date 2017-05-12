package TestMasonApp::InterpExecFromFile;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{param} = "success";
    $self->stash->{template} = "/InterpExecFromFile.mason";
    return $self->interp_exec;
}

1;

