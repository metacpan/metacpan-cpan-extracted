package TestApp::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';
use utf8;

__PACKAGE__->config->{namespace} = '';

sub chain_root_index : Chained('/') PathPart('') Args(0) { }

sub class_forward_test_method :Private {
}

sub bar : Chained Args {}
sub quux : Chained Args {}
sub test : Chained Args(0) {}
sub yada : Chained Args {}

1;
