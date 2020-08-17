use Test::Most;

use strict;
use warnings;

use lib 't/lib/';
use Test::CGI::Application::Plugin::OpenTracing::Utils;

sub add_callback {};

BEGIN { $ENV{OPENTRACING_IMPLEMENTATION} = 'X'; }

use_throws_ok( 'CGI::Application::Plugin::OpenTracing::DataDog', qr/not 'X'/ );

done_testing;

1;