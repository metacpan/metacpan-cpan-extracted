package TestMasonApp::InterpExecFromFH;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{param} = "success";
    $self->stash->{template} = \*DATA;
    return $self->interp_exec;
}

1;

__DATA__
<%args>
$param
</%args>
<html>
<head>
<title>InterpExecFromFH</title>
</head>

<body>
param : <% $param %>
</body>
</html>


