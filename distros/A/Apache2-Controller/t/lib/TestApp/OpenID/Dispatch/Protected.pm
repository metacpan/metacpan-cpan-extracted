package TestApp::OpenID::Dispatch::Protected;
use base qw( Apache2::Controller::Dispatch::Simple );
sub dispatch_map {{ 
    default   => 'TestApp::OpenID::C::Protected',
}}
1;
