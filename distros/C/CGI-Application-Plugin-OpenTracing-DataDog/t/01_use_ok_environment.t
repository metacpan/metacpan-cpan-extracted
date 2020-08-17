use Test::Most;

use strict;
use warnings;

sub add_callback {};

BEGIN { undef $ENV{OPENTRACING_IMPLEMENTATION} }

use_ok 'CGI::Application::Plugin::OpenTracing::DataDog';

done_testing;
