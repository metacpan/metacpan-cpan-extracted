use Test::Most;
use Test::MockObject;
use Test::OpenTracing::Integration;
use Test::WWW::Mechanize::CGIApp;

my $mech = Test::WWW::Mechanize::CGIApp->new;
$mech->app('MyTest::CGI::Application');

$mech->get('https://test.tst/test.cgi',
    'OpenTracing-Trace-Id' => 1234,
    'OpenTracing-Span-Id'  => 1111,
);
global_tracer_cmp_easy([
    {
        trace_id => 1234,
    },
], "trace_id inherited from headers");
done_testing();



package MyTest::CGI::Application;

use base 'CGI::Application';

use CGI::Application::Plugin::OpenTracing qw/Test/;
use OpenTracing::GlobalTracer qw/$TRACER/;

sub run_modes {
    start => 'foo',
}

sub foo { return }

1;
