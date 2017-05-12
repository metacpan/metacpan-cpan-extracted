use strict;
use warnings;
use Test::More tests => 1;
use CGI::Application 3.21;
use base qw(CGI::Application);

BEGIN { use_ok 'CGI::Application::Plugin::DebugMessage' }
