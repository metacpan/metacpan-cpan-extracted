package TestApp::Render::Dispatch;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller::Dispatch::Simple
);

use Log::Log4perl qw(:easy);

sub dispatch_map { {
    default     => 'TestApp::Render::Controller',
    foo         => 'TestApp::Render::C::Foo',
    multipath       => 'TestApp::Render::C::Multipath',
} }

1;
