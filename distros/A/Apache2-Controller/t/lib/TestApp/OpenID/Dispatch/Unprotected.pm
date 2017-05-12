package TestApp::OpenID::Dispatch::Unprotected;
use base qw( Apache2::Controller::Dispatch::Simple );
sub dispatch_map {{ 
    setup       => 'TestApp::OpenID::C::Setup',
}}
1;
