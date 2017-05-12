#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More;
# This kludge is necessary to avoid failing due to circular dependencies
# with Catalyst-Runtime. Not ideal, but until we remove CDR from
# Catalyst-Runtime prereqs, this is necessary to avoid Catalyst-Runtime build
# failing.
BEGIN {
    plan skip_all => 'Catalyst::Runtime required'
        unless eval { require Catalyst };
    plan skip_all => 'Test requires Catalyst::Runtime >= 5.90030' unless $Catalyst::VERSION >= 5.90030;
    plan tests => 39*$iters;
}

use Catalyst::Test 'TestApp';
use Catalyst::Request;

if ( $ENV{CAT_BENCHMARK} ) {
    require Benchmark;
    Benchmark::timethis( $iters, \&run_tests );
}
else {
    for ( 1 .. $iters ) {
        run_tests();
    }
}

sub run_tests {
    { # Test a Path action to make sure the setup is working
        ok( my $response = request('http://localhost/action/regexp/zero'),
            'Request Path' );
        ok( $response->is_success, '... Response Successful 2xx' );
        is( $response->content_type, 'text/plain', '... Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/regexp/zero', '... Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            '... Test Class'
        );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            '... Content is a serialized Catalyst::Request'
        );
    }
    { # Test LocalRegex()
        ok( my $response = request('http://localhost/action/regexp/10/hello'),
            'Request LocalRegex()' );
        ok( $response->is_success, '... Response Successful 2xx' );
        is( $response->content_type, 'text/plain', '... Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(\d+)/(\w+)$', '... Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            '... Test Class'
        );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            '... Content is a serialized Catalyst::Request'
        );
    }

    { # Test Regex()
        ok( my $response = request('http://localhost/action/regexp/hello/10'),
            'Request Regex()' );
        ok( $response->is_success, '... Response Successful 2xx' );
        is( $response->content_type, 'text/plain', '... Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(\w+)/(\d+)$', '... Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            '... Test Class'
        );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            '... Content is a serialized Catalyst::Request'
        );
    }

    { # Test LocalRegex(w/o optional capture)
        ok( my $response = request('http://localhost/action/regexp/mandatory'),
            'Request LocalRegex()' );
        ok( $response->is_success, '... Response Successful 2xx' );
        is( $response->content_type, 'text/plain', '... Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(mandatory)(/optional)?$', '... Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            '... Test Class'
        );
        my $content = $response->content;
        my $req = eval $content; 

        is( scalar @{ $req->captures }, 2, '... number of captures' );
        is( $req->captures->[ 0 ], 'mandatory', '... mandatory capture' );
        ok( !defined $req->captures->[ 1 ], '... optional capture' );
    }

    { # Test LocalRegex(w/ optional capture)
        ok( my $response = request('http://localhost/action/regexp/mandatory/optional'),
            'Request LocalRegex()' );
        ok( $response->is_success, '... Response Successful 2xx' );
        is( $response->content_type, 'text/plain', '... Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(mandatory)(/optional)?$', '... Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            '... Test Class'
        );
        my $content = $response->content;
        my $req = eval $content; 

        is( scalar @{ $req->captures }, 2, '... number of captures' );
        is( $req->captures->[ 0 ], 'mandatory', '... mandatory capture' );
        is( $req->captures->[ 1 ], '/optional', '... optional capture' );
    }

    # { # Test localregex in the root controller
    #     ok( my $response = request('http://localhost/localregex'),
    #         'Request' );
    #     ok( $response->is_success, '... Response Successful 2xx' );
    #     is( $response->content_type, 'text/plain', '... Response Content-Type' );
    #     is( $response->header('X-Catalyst-Action'),
    #         '^localregex$', '... Test Action' );
    #     is(
    #         $response->header('X-Test-Class'),
    #         'TestApp::Controller::Root',
    #         '... Test Class'
    #     );
    # }

    { # Test Regex(w/ captures) and redirect
        my $url = 'http://localhost/action/regexp/redirect/life/universe/42/everything';
        ok( my $response = request($url),
            'Request Regex(w/ captures)' );
        ok( $response->is_redirect, '... Response is redirect' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/redirect/(\w+)/universe/(\d+)/everything$',
            '... Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            '... Test Class'
        );
        is(
            $response->header('location'),
            $response->request->uri,
            '... Redirect URI is the same as the request URI'
        );
    }
}

