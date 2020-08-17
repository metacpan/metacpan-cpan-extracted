use Test::Most;

use strict;
use warnings;

sub add_callback {};

BEGIN { $ENV{OPENTRACING_IMPLEMENTATION} = 'NoOp' }

use_ok 'CGI::Application::Plugin::OpenTracing::DataDog';

done_testing;
