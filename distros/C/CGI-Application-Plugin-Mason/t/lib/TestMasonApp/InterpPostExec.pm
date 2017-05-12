package TestMasonApp::InterpPostExec;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->add_callback("interp_post_exec", sub {
                                                my($self, $bodyref) = @_;
                                                # success => post_exec_success
                                                ${$bodyref} =~ s/success/post_exec change/;
                                          });
    $self->stash->{param}    = "success";
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
<title>InterpPostExec</title>
</head>

<body>
param : <% $param %>
</body>
</html>

