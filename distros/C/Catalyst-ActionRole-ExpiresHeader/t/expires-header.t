use strict;
use warnings;
use Test::More tests => 54;

use DateTime::Format::DateParse;

use lib qw( t/lib );
use Catalyst::Test 'TestApp';

my @controllers = qw(
    expireswithactionroles
    expireswithdoes
);
my $resp;

for my $controller ( @controllers ) {
    #
    $resp = request("/$controller/expires_in_one_day");
    ok($resp->is_success,
        "request to /$controller/expires_in_one_day is succesful"
    );
    is($resp->content, join(':', qw( expires_in_one_day Expires +1d ) ),
        "...and content is correct"
    );
    ok( check_timediff(
            $resp->header('Expires'),
            { days => 1 }
        ),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/expires_fixed");
    ok($resp->is_success,
        "request to /$controller/expires_fixed is succesful"
    );
    is($resp->content, join(':', qw( expires_fixed Expires ), 'Wed, 26 May 2010 12:37:59 GMT' ),
        "...and content is correct"
    );
    is( $resp->header('Expires'),
        'Wed, 26 May 2010 12:37:59 GMT',
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/already_expired");
    ok($resp->is_success,
        "request to /$controller/already_expired is succesful"
    );
    is($resp->content, join(':', qw( already_expired Expires -1d ) ),
        "...and content is correct"
    );
    ok( check_timediff(
            $resp->header('Expires'),
            { days => -1 }
        ),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/expires_already_set");
    ok($resp->is_success,
        "request to /$controller/expires_already_set is succesful"
    );
    is($resp->content, join(':', qw( expires_already_set Expires +1h ) ),
        "...and content is correct"
    );
    ok( check_timediff(
            $resp->header('Expires'),
            { hours => 1 }
        ),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/no_expires");
    ok($resp->is_success,
        "request to /$controller/no_expires is succesful"
    );
    is($resp->content, join(':', qw( no_expires ) ),
        "...and content is correct"
    );
    ok( ! $resp->header('Expires'),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/empty_expires");
    ok($resp->is_success,
        "request to /$controller/empty_expires is succesful"
    );
    is($resp->content, join(':', qw( empty_expires Expires ), '' ),
        "...and content is correct"
    );
    ok( check_timediff(
            $resp->header('Expires'),
            { }
        ),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/zero_expires");
    ok($resp->is_success,
        "request to /$controller/zero_expires is succesful"
    );
    is($resp->content, join(':', qw( zero_expires Expires  0) ),
        "...and content is correct"
    );
    ok( check_timediff(
            $resp->header('Expires'),
            { }
        ),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/expires_now");
    ok($resp->is_success,
        "request to /$controller/expires_now is succesful"
    );
    is($resp->content, join(':', qw( expires_now Expires now ) ),
        "...and content is correct"
    );
    ok( check_timediff(
            $resp->header('Expires'),
            {  }
        ),
        "...and Expires header correct"
    );

    #
    $resp = request("/$controller/expires_in_epoch");
    ok($resp->is_success,
        "request to /$controller/expires_in_epoch is succesful"
    );
    is($resp->content, join(':', qw( expires_in_epoch Expires 1274879357 ) ),
        "...and content is correct"
    );
    is( $resp->header('Expires'),
        'Wed, 26 May 2010 13:09:17 GMT',
        "...and Expires header correct"
    );
}


sub check_timediff {
    my $expires = DateTime::Format::DateParse->parse_datetime($_[0])
        ->set_time_zone('UTC');
    my $target = DateTime->now( time_zone => 'UTC' )->add( %{ $_[1] } );

    my $time_diff = abs( $expires->epoch - $target->epoch );

    return $time_diff <= 2 ? 1 : 0;
}
