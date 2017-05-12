package TestMasonApp::InterpPreExec;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->add_callback("interp_pre_exec", sub {
                                                my($self, $template, $args) = @_;
                                                $args->{pre_exec_param} = "pre_exec success";
                                          });
    $self->stash->{param}    = "success";
    $self->stash->{template} = \*DATA;
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

