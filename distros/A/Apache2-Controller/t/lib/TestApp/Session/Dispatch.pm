package TestApp::Session::Dispatch;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller::Dispatch::Simple
);

use Log::Log4perl qw(:easy);

sub dispatch_map { {
    default     => 'TestApp::Session::Controller',
} }

1;
