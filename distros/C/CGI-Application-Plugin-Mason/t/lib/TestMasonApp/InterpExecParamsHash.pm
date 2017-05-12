package TestMasonApp::InterpExecParamsHash;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{template} = \*DATA;
    return $self->interp_exec( hashref => { fruit => "apple", music => "rock", sport => "baseball" } );
}

1;

__DATA__
<%args>
$hashref
</%args>
<html>
<head>
<title>InterpExecParamsHash</title>
</head>

<body>
hashref:
<ul>
% while( my($key, $val) = each %{$hashref} ){
<li><% $key %> : <% $val %></li>
% }
</ul>
</body>
</html>

