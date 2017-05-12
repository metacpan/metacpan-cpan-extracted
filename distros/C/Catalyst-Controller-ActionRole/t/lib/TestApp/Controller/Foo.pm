package TestApp::Controller::Foo;

use Moose;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(
    action_roles => ['~Kooh']
);

sub foo  : Local Does('Moo') {}
sub bar  : Local Does('~Moo') {}
sub baz  : Local Does('+Moo') {}
sub quux : Local Does('Zoo') {}

1;
