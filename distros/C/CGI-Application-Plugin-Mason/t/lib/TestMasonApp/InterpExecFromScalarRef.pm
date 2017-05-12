package TestMasonApp::InterpExecFromScalarRef;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{param} = "success";
    $self->stash->{template} = \q{<%args>
$param
</%args>
<html>
<head>
<title>InterpExecFromScalarRef</title>
</head>

<body>
param : <% $param %>
</body>
</html>
};
    return $self->interp_exec;
}

1;

