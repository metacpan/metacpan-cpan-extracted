use Test::Most;

use strict;
use warnings;

use Test::WWW::Mechanize::CGIApp;

use lib 't/lib';
use UserAgent::Fake;
use JSON::MaybeXS;

my $fake_user_agent;

subtest 'Creste Fake UserAgent' => sub {
    
    lives_ok {
        $fake_user_agent = UserAgent::Fake->new;
    } "Created a 'fake_user_agent'"
    
    or return;
    
};

subtest 'Make a CGI request' => sub {
    
    my $mech = Test::WWW::Mechanize::CGIApp->new;
    $mech->app( 'MyTest::CGI::Application::Fake' );
    $mech->get_ok('/test.cgi');

};

subtest 'Check HTTP UserAgent' => sub {
    
    my @requests = $fake_user_agent->get_all_requests();
    my @structs = map {
        decode_json( $_->decoded_content )
    } @requests;
    my $span_data = $structs[-1];
    cmp_deeply(
        $span_data => [[
            superhashof {
                'meta'             => {
                    'component'        => "CGI::Application",
                    'http.method'      => "GET",
                    'http.status_code' => 200,
                    'http.url'         => "http://localhost/test.cgi",
                    'run_method'       => "some_method_start",
                    'run_mode'         => "start",
                },
                'name'             => "cgi_application_request",
                'resource'         => "fake_endpoint.cgi",
                'service'          => "MyTest::CGI::Application::Fake",
                'type'             => "web",
            }
        ]],
        "Did send expected span data"
    )
    
};



done_testing();



package MyTest::CGI::Application::Fake;
use base 'CGI::Application';
use CGI::Application::Plugin::OpenTracing::DataDog
    default_resource_name => "fake_endpoint.cgi",
;

sub run_modes {
    start    => 'some_method_start',
}

sub some_method_start { return }

sub opentracing_bootstrap_options {
    client => {
        http_user_agent => $fake_user_agent
    },
}


