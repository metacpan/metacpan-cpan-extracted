package TestApp::View::Mason2::NoAutoextend;
use strict;
use warnings;
use base qw(Catalyst::View::Mason2);

__PACKAGE__->config( autoextend_request_path => 0 );

1;
