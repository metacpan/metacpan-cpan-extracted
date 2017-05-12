#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use Try::Tiny;

use_ok( 'Business::Fixflo::Exception' );

throws_ok(
    sub { Business::Fixflo::Exception->throw },
    qr/Missing required arguments: message/,
    '->throw requires a message',
);

throws_ok(
    sub { Business::Fixflo::Exception->throw(
        message  => 'Boo!',
        code     => 400,
        response => '400 Bad Request',
        request  => { foo => 'bar' },
    ) },
    'Business::Fixflo::Exception',
    '->throw with message (plain text)',
);

is( $@->message,'Boo!',' ... message available' );
is( $@->description,'Boo!',' ... description available' );
is( $@->code,'400',' ... code available' );
is( $@->response,'400 Bad Request',' ... response available' );
cmp_deeply( $@->request,{ foo => 'bar' },' ... request available' );

note( "JSON coercion" );

throws_ok(
    sub { Business::Fixflo::Exception->throw(
        message => '{"Message":["The resource has already been confirmed"]}',
    ) },
    'Business::Fixflo::Exception',
    '->throw with message (JSON Fixflo error response)',
);

is(
    $@->message,
    'The resource has already been confirmed',
    ' ... message coerced and available'
);

throws_ok(
    sub { Business::Fixflo::Exception->throw(
        message => '{"Message":"The resource has already been confirmed"}',
    ) },
    'Business::Fixflo::Exception',
    '->throw with message (JSON custom error response)',
);

is(
    $@->message,
    'The resource has already been confirmed',
    ' ... message coerced and available'
);

throws_ok(
    sub { Business::Fixflo::Exception->throw(
        message => '["The resource has already been confirmed"]',
    ) },
    'Business::Fixflo::Exception',
    '->throw with message (JSON as ARRAY)',
);

is(
    $@->message,
    'The resource has already been confirmed',
    ' ... message coerced and available'
);

try {
    Business::Fixflo::Exception->throw(
        message => 'Boo!'
    );
}
catch {
    isa_ok( $_,'Business::Fixflo::Exception' );
    is( $_->message,'Boo!','Try::Tiny catches exceptions' );
};

done_testing();

# vim: ts=4:sw=4:et
