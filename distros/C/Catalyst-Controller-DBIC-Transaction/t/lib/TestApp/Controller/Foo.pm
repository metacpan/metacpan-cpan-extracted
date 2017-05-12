package TestApp::Controller::Foo;

use base 'Catalyst::Controller::DBIC::Transaction';
use strict;
use warnings;

sub bar :Local :DBICTransaction('DB') {
    my ($self, $c) = @_;

    ::ok('Inside the method');
}


1;
