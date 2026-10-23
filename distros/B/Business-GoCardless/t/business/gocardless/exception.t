#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use Try::Tiny;
use Encode ();

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

note( "v2 API errors" );

throws_ok(
    sub { Business::GoCardless::Exception->throw(
        message => '{"error":{"type":"invalid_state","code":409,'
            . '"message":"A resource has already been created with this idempotency key",'
            . '"request_id":"REQ123","documentation_url":"https://developer.gocardless.com/api-reference#invalid_state",'
            . '"errors":[{"reason":"idempotent_creation_conflict","message":"Conflict",'
            . '"links":{"conflicting_resource_id":"PM123"}}]}}',
        code     => 409,
        response => '409 Conflict',
    ) },
    'Business::GoCardless::Exception',
    '->throw with message (JSON v2 API error response)',
);

is( $@->type,'invalid_state',' ... type' );
is( $@->request_id,'REQ123',' ... request_id' );
is( $@->documentation_url,'https://developer.gocardless.com/api-reference#invalid_state',' ... documentation_url' );
is( scalar( @{ $@->errors } ),1,' ... errors' );
is_deeply( [ $@->reasons ],[ 'idempotent_creation_conflict' ],' ... reasons' );
ok( $@->has_reason( 'idempotent_creation_conflict' ),' ... has_reason' );
is( $@->conflicting_resource_id,'PM123',' ... conflicting_resource_id' );
like(
    $@->message,
    qr/^A resource has already been created with this idempotency key \/ Conflict/,
    ' ... message coerced and available'
);

throws_ok(
    sub { Business::GoCardless::Exception->throw( message => 'Boo!' ) },
    'Business::GoCardless::Exception',
    '->throw with plain message',
);

ok( ! $@->type,' ... no type' );
is_deeply( $@->errors,[],' ... empty errors' );
is_deeply( [ $@->reasons ],[],' ... no reasons' );
ok( ! $@->has_reason( 'foo' ),' ... ! has_reason' );

note( "JSON decoding" );

my $error_json = sub {
    my ( $message ) = @_;
    return qq!{"error":{"type":"validation_failed","message":"$message","errors":[]}}!;
};

foreach my $t (
    [ 'UTF-8 encoded bytes',Encode::encode_utf8( $error_json->( "J\x{f8}h\x{f1}" ) ),"J\x{f8}h\x{f1}" ],
    [ 'characters (latin-1 range)',$error_json->( "J\x{f8}h\x{f1}" ),"J\x{f8}h\x{f1}" ],
    [ 'characters (wide)',$error_json->( "\x{2713} done" ),"\x{2713} done" ],
    [ 'ASCII',$error_json->( 'plain' ),'plain' ],
) {
    my ( $desc,$json,$expected ) = @{ $t };

    my $E = Business::GoCardless::Exception->new( message => $json );
    is( $E->type,'validation_failed',"$desc: details extracted" );
    is( $E->message,"$expected << $expected >> ","$desc: message decoded" );
}

my $invalid = Business::GoCardless::Exception->new(
    message => '{"error":{"message":"not closed"',
);
like(
    $invalid->message,
    qr/^Failed to parse JSON response .*: .+/,
    'invalid JSON reports the parse failure'
);
unlike( $invalid->message,qr/Wide character|malformed UTF-8/i,' ... not an encoding error' );
ok( ! $invalid->type,' ... no details extracted' );

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
