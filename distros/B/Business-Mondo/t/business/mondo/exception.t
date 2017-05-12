#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use Try::Tiny;

use_ok( 'Business::Mondo::Exception' );

throws_ok(
    sub { Business::Mondo::Exception->throw },
    qr/Missing required arguments: message/,
    '->throw requires a message',
);

throws_ok(
    sub { Business::Mondo::Exception->throw(
        message  => 'Boo!',
        code     => 400,
        response => '400 Bad Request',
    ) },
    'Business::Mondo::Exception',
    '->throw with message (plain text)',
);

is( $@->message,'Boo!',' ... message available' );
is( $@->description,'Boo!',' ... description available' );
is( $@->code,'400',' ... code available' );
is( $@->response,'400 Bad Request',' ... response available' );

try {
    Business::Mondo::Exception->throw(
        message => 'Boo!'
    );
}
catch {
    isa_ok( $_,'Business::Mondo::Exception' );
    is( $_->message,'Boo!','Try::Tiny catches exceptions' );
};

done_testing();

# vim: ts=4:sw=4:et
