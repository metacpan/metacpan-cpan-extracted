package TestApp;

use 5.10.0;

use strict;
use warnings;
no warnings qw/ uninitialized /;

use lib 't';

use Test::More;

use Dancer qw/:tests/;
use Dancer::Plugin::Cache::CHI;

use Dancer::Test;

my $api_version = int Dancer->VERSION;


set plugins => {
    'Cache::CHI' => { 
        driver => 'Memory', 
        global => 1, 
        expires_in => '1 min',
        'honor_no_cache' => 1,
    },
};

check_page_cache;

get '/cached' => sub {
    state $i;
    return cache_page ++$i;
};

plan tests => 4;

my $counter = 0;

response_content_is '/cached' => ++$counter, 'initial hit';
response_content_is '/cached' => $counter, 'cached';

subtest $_ => sub {
    plan tests => 2;

    my $resp = non_cached_request($_);

    response_content_is $resp => ++$counter, "$_: no-cache";
    response_content_is '/cached' => $counter, 'cached again';

} for qw/ Cache-Control Pragma /;


sub non_cached_request {
    my $header = $_;

    if ( $api_version < 2 ) {
        return dancer_response 'GET' => '/cached', {
            headers => [ $header => 'no-cache' ],
        };
    }

    my $request = Dancer::Core::Request->new(
        method => 'GET',
        path => '/cached',
    );

    $request->header( $header => 'no-cache' );

    return dancer_response $request;
}
