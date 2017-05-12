package CGI::Application::Plugin::AbstractCallback::Test::InitHook;

use strict;
use warnings;

use base qw|CGI::Application|;
use CGI::Application::Plugin::AbstractCallback::Test::InitSetter qw|init|;

1;