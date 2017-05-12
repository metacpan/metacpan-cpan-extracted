package TestMasonApp::InterpExecError;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{template} = "/none.mason";
    return $self->interp_exec;
}

1;

__DATA__
<%args>
$param
$pre_exec_param
</%args>
<html>
<head>
<title>InterpPreExec</title>
</head>

<body>
pre_exec_param : <% $pre_exec_param %><br>
param : <% $param %><br>
</body>
</html>

