package TestMasonApp::InterpExecSetEscape;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{param}    = qq{< > & ' "};
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
<title>InterpExecSetEscape</title>
</head>

<body>
param : <% $param | h %>
</body>
</html>

