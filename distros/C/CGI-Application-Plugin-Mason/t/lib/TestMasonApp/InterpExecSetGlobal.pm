package TestMasonApp::InterpExecSetGlobal;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{template} = \*DATA;
    return $self->interp_exec;
}

1;

__DATA__
<html>
<head>
<title>InterpExecSetGlobal</title>
</head>

<body>
mode : <% $c->get_current_runmode %>
</body>
</html>

