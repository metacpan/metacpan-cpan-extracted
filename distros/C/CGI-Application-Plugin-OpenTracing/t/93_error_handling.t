use Test::Most ;
use Test::MockObject;
use Test::OpenTracing::Integration;
use Test::WWW::Mechanize::CGIApp;



my $mech = Test::WWW::Mechanize::CGIApp->new();



lives_ok {
    $mech->app('MyTest::WithErrorBase');
} "Set Test::WWW::Mechanize app to 'MyTest::WithErrorBase'";



$mech->get('https://test.tst/test.cgi?rm=run_mode_204');

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_204',
                'http.status_code'      => 204,
                'http.status_message'   => 'No Content',
                'run_mode'              => 'run_mode_204',
                'run_method'            => 'method_204',
            },
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
    ], 'CGI::App [WithErrorBase/run_mode_204], Returns "No Content" at [method_204]'
);



eval { $mech->get('https://test.tst/test.cgi?rm=run_mode_die') };

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_die',
                'http.status_code'      => 500,
                'http.status_message'   => 'Internal Server Error',
                'run_mode'              => 'run_mode_die',
                'run_method'            => 'method_die',
                'error'                 => 1,
                'message'               => re(qr/Method Die/),
            },
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Method Die/),
            },
        },
    ], 'CGI::App [WithErrorBase/run_mode_die], dies "Method Die" at [method_die]'
);



eval { $mech->get('https://test.tst/test.cgi?rm=run_mode_one') };

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_one',
                'http.status_code'      => 500,
                'http.status_message'   => 'Internal Server Error',
                'run_mode'              => 'run_mode_one',
                'run_method'            => 'method_one',
                'error'                 => 1,
                'message'               => re(qr/Inside Die/),
            },      
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
        {
            operation_name          => 'level_one',
            level                   => 2,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Inside Die/),
            },
        },
    ], 'CGI::App [WithErrorBase/run_mode_one], dies "Inside Die" at [level_one/inside_die]'
);



eval { $mech->get('https://test.tst/test.cgi?rm=run_mode_two') };

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_two',
                'http.status_code'      => 500,
                'http.status_message'   => 'Internal Server Error',
                'run_mode'              => 'run_mode_two',
                'run_method'            => 'method_two',
                'error'                 => 1,
                'message'               => re(qr/Inside Die/),
                'error.kind'            => "MY_ERROR_TYPE"
            },      
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
        {
            operation_name          => 'level_one',
            level                   => 2,
            tags                    => { },
        },
        {
            operation_name          => 'level_two',
            level                   => 3,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Can't continue here .../),
                'error.kind'            => "MY_ERROR_TYPE"
            },
        },
    ], 'CGI::App [WithErrorBase/run_mode_two], dies "Inside Die" at [level_one/level_two/inside_die]'
);



eval { $mech->get('https://test.tst/test.cgi?rm=run_mode_xxx') };

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_xxx',
                'http.status_code'      => 500,
                'http.status_message'   => 'Internal Server Error',
                'error'                 => 1,
                'run_mode'              => 'run_mode_xxx',
                'message'               => re(qr/No such run mode/),
            },
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/No such run mode/),
            },
        },
    ], 'CGI::App [WithErrorBase/run_mode_xxx] invalid'
);



lives_ok {
    $mech->app('MyTest::WithErrorMode');
} "Set Test::WWW::Mechanize app to 'MyTest::WithErrorMode'";



$mech->get('https://test.tst/test.cgi?rm=run_mode_204');

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_204',
                'http.status_code'      => 204,
                'http.status_message'   => 'No Content',
                'run_mode'              => 'run_mode_204',
                'run_method'            => 'method_204',
            },
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
    ], 'CGI::App [WithErrorMode/run_mode_204], Returns "No Content" at [method_204]'
);



$mech->get('https://test.tst/test.cgi?rm=run_mode_die');

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_die',
                'http.status_code'      => '402',
                'http.status_message'   => "Payment Required",
                'run_mode'              => 'run_mode_die',
                'run_method'            => 'method_die',
            },
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Method Die/),
            },
        },
    ], 'CGI::App [WithErrorMode/run_mode_die], dies "Method Die" at [method_die]'
);



$mech->get('https://test.tst/test.cgi?rm=run_mode_one');

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_one',
                'http.status_code'      => '402',
                'http.status_message'   => "Payment Required",
                'run_mode'              => 'run_mode_one',
                'run_method'            => 'method_one',
            },
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
        {
            operation_name          => 'level_one',
            level                   => 2,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Inside Die/),
            },
        },
    ], 'CGI::App [WithErrorMode/run_mode_one], dies "Inside Die" at [level_one/inside_die]'
);



eval { $mech->get('https://test.tst/test.cgi?rm=run_mode_two') };

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_two',
                'http.status_code'      => 402,
                'http.status_message'   => "Payment Required",
                'run_mode'              => 'run_mode_two',
                'run_method'            => 'method_two',
            },      
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
        {
            operation_name          => 'level_one',
            level                   => 2,
            tags                    => { },
        },
        {
            operation_name          => 'level_two',
            level                   => 3,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Can't continue here .../),
                'error.kind'            => "MY_ERROR_TYPE"
            },
        },
    ], 'CGI::App [WithErrorMode/run_mode_two], dies "Inside Die" at [level_one/level_two/inside_die]'
);



lives_ok {
    $mech->app('MyTest::WithErrorSrvr');
} "Set Test::WWW::Mechanize app to 'MyTest::WithErrorSrvr'";



eval { $mech->get('https://test.tst/test.cgi?rm=run_mode_two') };

global_tracer_cmp_easy(
    [
        {
            operation_name          => 'cgi_application_request',
            level                   => 0,
            tags                    => {
                'component'             => 'CGI::Application',
                'http.method'           => 'GET',
                'http.url'              => 'https://test.tst/test.cgi',
                'http.query.rm'         => 'run_mode_two',
                'http.status_code'      => 502,
                'http.status_message'   => "Bad Gateway",
                'run_mode'              => 'run_mode_two',
                'run_method'            => 'method_two',
                'error'                 => 1,
            },      
        },
        {
            operation_name          => 'cgi_application_run',
            level                   => 1,
            tags                    => { },
        },
        {
            operation_name          => 'level_one',
            level                   => 2,
            tags                    => { },
        },
        {
            operation_name          => 'level_two',
            level                   => 3,
            tags                    => {
                'error'                 => 1,
                'message'               => re(qr/Can't continue here .../),
                'error.kind'            => "MY_ERROR_TYPE"
            },
        },
    ], 'CGI::App [WithErrorSrvr/run_mode_two], dies "Inside Die" at [level_one/level_two/inside_die]'
);



done_testing();



package MyTest::WithErrorBase;
use base 'CGI::Application';

use CGI::Application::Plugin::OpenTracing qw/Test/;
use OpenTracing::GlobalTracer qw/$TRACER/;

sub run_modes {
    run_mode_die => 'method_die',
    run_mode_one => 'method_one',
    run_mode_two => 'method_two',
    run_mode_204 => 'method_204',
}

sub method_die { die 'Something wrong within "Method Die"' }

sub method_one {
    my $scope = $TRACER->start_active_span('level_one');
    inside_die();
}

sub method_two {
    my $scope = $TRACER->start_active_span('level_one');
    inside_two()    
}

sub method_204 { $_[0]->header_add(-status => '204') }

sub inside_two {
    my $scope = $TRACER->start_active_span('level_two');
    eval {
        inside_die();
    };
    if ( my $error = $@ ) {
        $scope->get_span()->add_tags(
            'error'      => 1,
            'message'    => "Can't continue here ...",
            'error.kind' => "MY_ERROR_TYPE"
        );
        die $error;
    }
}

sub inside_die { die 'Something wrong within "Inside Die"' }



package MyTest::WithErrorMode;
use base 'MyTest::WithErrorBase';

sub cgiapp_init { $_[0]->error_mode('show_error') }

sub show_error {
    my $self = shift;

    $self->header_add(-status => '402');

    return 'Pay up'
}


package MyTest::WithErrorSrvr;
use base 'MyTest::WithErrorBase';

sub cgiapp_init { $_[0]->error_mode('show_error') }

sub show_error {
    my $self = shift;

    $self->header_add(-status => '502');

    return 'Something bad is happening'
}
