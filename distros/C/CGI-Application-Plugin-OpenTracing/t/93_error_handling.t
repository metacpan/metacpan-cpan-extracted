use Test::Most ;
use Test::MockObject;
use Test::OpenTracing::Integration;
use Test::WWW::Mechanize::CGIApp;

{
    package MyTest::DyingApp;
    use base 'CGI::Application';

    use CGI::Application::Plugin::OpenTracing qw/Test/;
    use OpenTracing::GlobalTracer qw/$TRACER/;

    sub run_modes {
        run_fail  => 'broken_method',
        run_break => 'broken_span',
    }

    sub broken_method { die 'Something wrong' }

    sub broken_span {
        my $scope = $TRACER->start_active_span('broken');
        broken_method();
    }
}

my $mech = Test::WWW::Mechanize::CGIApp->new(app => 'MyTest::DyingApp');

eval { $mech->get('https://test.tst/test.cgi?rm=run_fail') };
global_tracer_cmp_easy(
    [
        {
            operation_name      => 'cgi_application_request',
            level               => 0,
            tags => {
                'component'        => 'CGI::Application',
                'http.method'      => 'GET',
                'http.url'         => 'https://test.tst/test.cgi',
                'http.query.rm'    => 'run_fail',
                'http.status_code' => 500,
                'run_mode'         => 'run_fail',
                'run_method'       => 'broken_method',
                'error'            => 1,
                'message'          => re(qr/Something wrong/),
            },
        },
    ], 'run_method dies and no on_error handler is defined'
);

eval { $mech->get('https://test.tst/test.cgi?rm=run_break') };
global_tracer_cmp_easy(
    [
        {
            operation_name      => 'cgi_application_request',
            level               => 0,
            tags => {
                'component'        => 'CGI::Application',
                'http.method'      => 'GET',
                'http.url'         => 'https://test.tst/test.cgi',
                'http.query.rm'    => 'run_break',
                'http.status_code' => 500,
                'run_mode'         => 'run_break',
                'run_method'       => 'broken_span',
                'error'            => 1,
                'message'          => re(qr/Something wrong/),
            },
        },
        {
            operation_name => 'broken',
            tags           => {
                'error' => 1,
                'message' => re(qr/Something wrong/),
            },
        },
    ], 'run_method with an embedded span dies'
);

{
    package MyTest::SurvivingApp;
    use base 'MyTest::DyingApp';

    sub cgiapp_init { $_[0]->error_mode('show_error') }

    sub show_error {
        my $self = shift;

        $self->header_add(-status => '402');

        return 'Pay up'
    }
}

$mech = Test::WWW::Mechanize::CGIApp->new(app => 'MyTest::SurvivingApp');

$mech->get('https://test.tst/test.cgi?rm=run_fail');
global_tracer_cmp_easy(
    [
        {
            operation_name      => 'cgi_application_request',
            level               => 0,
            tags                => {
                'component'           => 'CGI::Application',
                'http.method'         => 'GET',
                'http.url'            => 'https://test.tst/test.cgi',
                'http.query.rm'       => 'run_fail',
                'http.status_code'    => '402',
                'http.status_message' => "Payment Required",
                'run_mode'            => 'run_fail',
                'run_method'          => 'broken_method',
            },
        },
    ], 'run_method dies and an on_error handler is defined'
);

$mech->get('https://test.tst/test.cgi?rm=run_break');
global_tracer_cmp_easy(
    [
        {
            operation_name      => 'cgi_application_request',
            level               => 0,
            tags                => {
                'component'           => 'CGI::Application',
                'http.method'         => 'GET',
                'http.url'            => 'https://test.tst/test.cgi',
                'http.query.rm'       => 'run_break',
                'http.status_code'    => '402',
                'http.status_message' => "Payment Required",
                'run_mode'            => 'run_break',
                'run_method'          => 'broken_span',
            },
        },
        {
            operation_name => 'broken',
            tags           => {
                'error' => 1,
                'message' => re(qr/Something wrong/),
            },
        },
    ], 'run_method with an embedded span dies with an on_error handler'
);

done_testing();
