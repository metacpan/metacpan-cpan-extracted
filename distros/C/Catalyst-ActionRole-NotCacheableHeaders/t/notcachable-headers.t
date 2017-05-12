use strict;
use warnings;
use Test::More tests => 36;

use DateTime::Format::DateParse;

use lib qw( t/lib );
use Catalyst::Test 'TestApp';

my @controllers = qw(
    notcacheablewithactionroles
    notcacheablewithdoes
);
my $resp;

for my $controller ( @controllers ) {
    #
    $resp = request("/$controller/dont_cache_me");
    ok($resp->is_success,
        "request to /$controller/dont_cache_me is succesful"
    );
    is($resp->content, join(':', qw( dont_cache_me ) ),
        "...and content is correct"
    );
    is( $resp->header('Pragma'), 'no-cache',
        '...and Pragma was set'
    );
    is( $resp->header('Cache-Control'), 'no-cache',
        '...and Cache-Control was set'
    );
    is( $resp->header('Expires'), 'Thu, 01 Jan 1970 00:00:00 GMT',
        '...and Expires was set'
    );
    ok( check_timediff(
            $resp->header('Last-Modified'),
            { }
        ),
        "...and Last-Modified was set"
    );

    #
    $resp = request("/$controller/no_notcacheable");
    ok($resp->is_success,
        "request to /$controller/no_notcacheable is succesful"
    );
    is($resp->content, join(':', qw( no_notcacheable ) ),
        "...and content is correct"
    );
    ok( ! $resp->header($_),
        "...and $_ was not set"
    ) for qw( Pragma Cache-Control Expires Last-Modified );

    #
    $resp = request("/$controller/own_headers");
    ok($resp->is_success,
        "request to /$controller/own_headers is succesful"
    );
    is($resp->content, join(':', qw( own_headers ) ),
        "...and content is correct"
    );
    is( $resp->header('Pragma'), 'no-cache',
        '...and Pragma was set'
    );
    is( $resp->header('Cache-Control'), 'no-cache',
        '...and Cache-Control has overwritten previous value'
    );
    is( $resp->header('Expires'), 'Thu, 01 Jan 1970 00:00:00 GMT',
        '...and Expires has overwritten previous value'
    );
    ok( check_timediff(
            $resp->header('Last-Modified'),
            { }
        ),
        "...and Last-Modified has overwritten previous value"
    );


}


sub check_timediff {
    my $expires = DateTime::Format::DateParse->parse_datetime($_[0])
        ->set_time_zone('UTC');
    my $target = DateTime->now( time_zone => 'UTC' )->add( %{ $_[1] } );

    my $time_diff = abs( $expires->epoch - $target->epoch );

    return $time_diff <= 2 ? 1 : 0;
}
