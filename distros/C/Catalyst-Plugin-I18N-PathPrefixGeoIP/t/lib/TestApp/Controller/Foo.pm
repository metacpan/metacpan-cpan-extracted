package TestApp::Controller::Foo;

use Moose;

BEGIN {
  extends 'Catalyst::Controller';
}

sub bar :Local { }


__PACKAGE__->meta->make_immutable;

1;
