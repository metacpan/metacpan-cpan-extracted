package TestApp::Controller::Action::Chained::ArgsOrder;
use warnings;
use strict;

use base qw( Catalyst::Controller );

sub base  :Chained('/') PathPart('argsorder') CaptureArgs(0) {
}

sub index :Chained('base') PathPart('') Args(0) {
}

1;
