package TestApp::DBI::Dispatch;
use base qw( 
    Apache2::Controller::Dispatch::Simple 
);
sub dispatch_map {{ default => 'TestApp::DBI::Controller' }}
1;
