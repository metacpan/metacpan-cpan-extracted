#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use Try::Tiny;

use_ok( 'Business::GoCardless::Exception' );

throws_ok(
    sub { Business::GoCardless::Exception->throw },
    qr/Missing required arguments: message/,
    '->throw requires a message',
);

throws_ok(
    sub { Business::GoCardless::Exception->throw(
        message  => 'Boo!',
        code     => 400,
        response => '400 Bad Request',
    ) },
    'Business::GoCardless::Exception',
    '->throw with message (plain text)',
);

is( $@->message,'Boo!',' ... message available' );
is( $@->description,'Boo!',' ... description available' );
is( $@->code,'400',' ... code available' );
is( $@->response,'400 Bad Request',' ... response available' );

note( "JSON coercion" );

throws_ok(
    sub { Business::GoCardless::Exception->throw(
        message => '{"error":["The resource has already been confirmed"]}',
    ) },
    'Business::GoCardless::Exception',
    '->throw with message (JSON GoCardless error response)',
);

is(
    $@->message,
    'The resource has already been confirmed',
    ' ... message coerced and available'
);

throws_ok(
    sub { Business::GoCardless::Exception->throw(
        message => '{"error":"The resource has already been confirmed"}',
    ) },
    'Business::GoCardless::Exception',
    '->throw with message (JSON custom error response)',
);

is(
    $@->message,
    'The resource has already been confirmed',
    ' ... message coerced and available'
);

throws_ok(
    sub { Business::GoCardless::Exception->throw(
        message => '["The resource has already been confirmed"]',
    ) },
    'Business::GoCardless::Exception',
    '->throw with message (JSON as ARRAY)',
);

is(
    $@->message,
    'The resource has already been confirmed',
    ' ... message coerced and available'
);

try {
    Business::GoCardless::Exception->throw(
        message => 'Boo!'
    );
}
catch {
    isa_ok( $_,'Business::GoCardless::Exception' );
    is( $_->message,'Boo!','Try::Tiny catches exceptions' );
};

done_testing();

# vim: ts=4:sw=4:et
