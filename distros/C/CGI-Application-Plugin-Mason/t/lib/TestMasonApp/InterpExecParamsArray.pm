package TestMasonApp::InterpExecParamsArray;

use base qw(TestMasonApp::Base);
use strict;
use warnings;

sub index {
    my $self = shift;
    $self->stash->{template} = \*DATA;
    return $self->interp_exec( aryref => [ "apple", "banana", "melon" ] );
}

1;

__DATA__
<%args>
$aryref
</%args>
<html>
<head>
<title>InterpExecParamsArray</title>
</head>

<body>
arrayref:
<ul>
% foreach my $val(@{$aryref}){
<li><% $val %></li>
% }
</ul>
</body>
</html>

