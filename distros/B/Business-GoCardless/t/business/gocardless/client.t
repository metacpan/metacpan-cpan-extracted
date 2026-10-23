#!perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Test::Deep;
use Test::Exception;
use HTTP::Response;
use HTTP::Date qw/ time2str /;
use JSON ();
use Encode ();
use POSIX ();

use_ok( 'Business::GoCardless::Client' );
isa_ok(
    my $Client = Business::GoCardless::Client->new(
        token       => 'MvYX0i6snRh/1PXfPoc6',
        app_id      => 'some application',
        app_secret  => 'setec astronomy',
        merchant_id => '1DJUN3H1I2',
    ),
    'Business::GoCardless::Client'
);

can_ok(
    $Client,
    qw/
        token
        base_url
        api_path
        app_id
        app_secret
        merchant_id
        max_retries
        max_retry_wait
        raise_on_idempotency_conflict
        rate_limit
        api_get
        api_post
        api_put
        api_delete
    /,
);

is( $Client->max_retries,3,'max_retries default' );
is( $Client->max_retry_wait,60,'max_retry_wait default' );
ok( ! $Client->raise_on_idempotency_conflict,'raise_on_idempotency_conflict default' );
ok( ! $Client->rate_limit,'no rate_limit before any requests' );

# monkey patching LWP here to make this test work without having to actually
# hit the endpoints - each request gets the next response in @responses
no warnings 'redefine';
no warnings 'once';

my ( @responses,@requests,@sleeps );

*LWP::UserAgent::request = sub {
    my ( $ua,$req ) = @_;
    push( @requests,$req );
    return shift( @responses ) // die "No more responses";
};

*Business::GoCardless::Client::_sleep = sub { push( @sleeps,$_[1] ) };

sub _response {
    my ( $code,$data,%headers ) = @_;

    my $res = HTTP::Response->new( $code );
    $res->header( %headers ) if %headers;
    $res->content( Encode::encode_utf8( JSON->new->encode( $data ) ) )
        if defined $data;
    return $res;
}

sub _error {
    my ( $code,$type,@errors ) = @_;

    return _response( $code,{ error => {
        type              => $type,
        code              => $code,
        message           => "An error ($type)",
        request_id        => 'REQ123',
        documentation_url => 'https://developer.gocardless.com/api-reference#' . $type,
        errors            => [ @errors ],
    } } );
}

sub _reset {
    @responses = @_;
    @requests  = ();
    @sleeps    = ();
}

my $uuid_re = qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

my $Pro = Business::GoCardless::Client->new(
    token       => 'foo',
    api_version => 2,
);

note( "Idempotency keys" );

_reset( _response( 201,{ payments => { id => 'PM123' } } ) );
cmp_deeply(
    scalar( $Pro->api_post( '/payments',{ payments => { amount => 100 } } ) ),
    { payments => { id => 'PM123' } },
    '->api_post (create)'
);
like(
    $requests[0]->header( 'Idempotency-Key' ),
    $uuid_re,
    ' ... sends a UUID v4 Idempotency-Key',
);

_reset(
    _response( 201,{ payments => { id => 'PM123' } } ),
    _response( 201,{ payments => { id => 'PM456' } } ),
);
$Pro->api_post( '/payments',{} ) for 1 .. 2;
isnt(
    $requests[0]->header( 'Idempotency-Key' ),
    $requests[1]->header( 'Idempotency-Key' ),
    ' ... a different key for each request'
);

_reset( _response( 201,{ payments => { id => 'PM123' } } ) );
$Pro->api_post( '/payments',{},{ 'Idempotency-Key' => 'my-key' } );
is( $requests[0]->header( 'Idempotency-Key' ),'my-key',' ... can pass own key' );

_reset( _response( 200,{ payments => { id => 'PM123' } } ) );
$Pro->api_post( '/payments/PM123/actions/cancel' );
ok( ! $requests[0]->header( 'Idempotency-Key' ),'no Idempotency-Key for actions' );

_reset( _response( 200,{ payments => { id => 'PM123' } } ) );
$Pro->api_get( '/payments/PM123' );
ok( ! $requests[0]->header( 'Idempotency-Key' ),'no Idempotency-Key for GET' );

SKIP: {
    skip( "fork not supported",1 ) if $^O eq 'MSWin32';

    # e.g. under a preforking web server, the same key in different
    # processes would wrongly return another process's resource
    $Pro->_generate_idempotency_key; # make sure the generator is seeded
    pipe( my $reader,my $writer ) or die "pipe: $!";

    if ( my $pid = fork ) {
        close( $writer );
        my $child_key = <$reader>;
        waitpid( $pid,0 );
        isnt( $child_key,$Pro->_generate_idempotency_key,'forked processes generate different keys' );
    } else {
        close( $reader );
        print $writer $Pro->_generate_idempotency_key;
        close( $writer );
        POSIX::_exit( 0 );
    }
}

note( "Idempotency conflicts" );

my $conflict = _error( 409,'invalid_state',{
    reason  => 'idempotent_creation_conflict',
    message => 'A resource has already been created with this idempotency key',
    links   => { conflicting_resource_id => 'PM123' },
} );

_reset(
    _response( 500,{ error => { message => 'Internal error' } } ),
    $conflict,
    _response( 200,{ payments => { id => 'PM123',status => 'pending_submission' } } ),
);

cmp_deeply(
    scalar( $Pro->api_post( '/payments',{ payments => { amount => 100 } } ) ),
    { payments => { id => 'PM123',status => 'pending_submission' } },
    'conflict after a retry returns the existing resource'
);

cmp_deeply(
    [ map { $_->method . ' ' . $_->uri->path } @requests ],
    [ 'POST /payments','POST /payments','GET /payments/PM123' ],
    ' ... retried the POST then fetched the existing resource'
);

is(
    $requests[0]->header( 'Idempotency-Key' ),
    $requests[1]->header( 'Idempotency-Key' ),
    ' ... using the same Idempotency-Key for the retry'
);

my $RaisePro = Business::GoCardless::Client->new(
    token                         => 'foo',
    api_version                   => 2,
    raise_on_idempotency_conflict => 1,
);

_reset( $conflict );
throws_ok(
    sub { $RaisePro->api_post( '/payments',{} ) },
    'Business::GoCardless::Exception',
    'raise_on_idempotency_conflict throws on conflict'
);
is( $@->code,409,' ... with code' );
is( $@->conflicting_resource_id,'PM123',' ... and conflicting_resource_id' );
is( scalar( @requests ),1,' ... without fetching the resource' );

note( "Retries" );

_reset(
    _response( 503 ),
    _response( 502 ),
    _response( 200,{ payments => { id => 'PM123' } } ),
);
cmp_deeply(
    scalar( $Pro->api_get( '/payments/PM123' ) ),
    { payments => { id => 'PM123' } },
    'GET retried on server errors'
);
cmp_deeply( \@sleeps,[ 0.5,1 ],' ... with exponential backoff' );

_reset( map { _response( 500 ) } 1 .. 4 );
throws_ok(
    sub { $Pro->api_get( '/payments/PM123' ) },
    'Business::GoCardless::Exception',
    'throws once max_retries are exhausted'
);
is( scalar( @requests ),4,' ... after 1 request + 3 retries' );
cmp_deeply( \@sleeps,[ 0.5,1,2 ],' ... with exponential backoff' );

_reset( _response( 500 ) );
throws_ok(
    sub { $Pro->api_post( '/payments/PM123/actions/cancel' ) },
    'Business::GoCardless::Exception',
    'POST to an action is not retried on server error'
);
is( scalar( @requests ),1,' ... only one request made' );

_reset( _error( 422,'validation_failed',{ field => 'amount',message => 'is required' } ) );
throws_ok(
    sub { $Pro->api_post( '/payments',{} ) },
    'Business::GoCardless::Exception',
    'client errors are not retried'
);
is( scalar( @requests ),1,' ... only one request made' );

my $NoRetryPro = Business::GoCardless::Client->new(
    token       => 'foo',
    api_version => 2,
    max_retries => 0,
);

_reset( _response( 503 ) );
throws_ok(
    sub { $NoRetryPro->api_get( '/payments/PM123' ) },
    'Business::GoCardless::Exception',
    'max_retries => 0 disables retries'
);
is( scalar( @requests ),1,' ... only one request made' );

note( "Rate limiting" );

my %rate_limit_headers = (
    'RateLimit-Limit'     => 1000,
    'RateLimit-Remaining' => 0,
    'RateLimit-Reset'     => time2str( time + 5 ),
);

_reset(
    _response( 429,{ error => { message => 'Rate limit exceeded' } },%rate_limit_headers ),
    _response( 200,{ payments => { id => 'PM123' } },
        'RateLimit-Limit'     => 1000,
        'RateLimit-Remaining' => 999,
        'RateLimit-Reset'     => 'Thu, 03 May 2018 16:00:00 GMT',
    ),
);

$Pro->api_post( '/payments/PM123/actions/cancel' );
is( scalar( @requests ),2,'rate limited action is retried' );
ok( $sleeps[0] > 3 && $sleeps[0] <= 5,' ... after waiting until ratelimit-reset' );

cmp_deeply(
    $Pro->rate_limit,
    {
        limit     => 1000,
        remaining => 999,
        reset     => 'Thu, 03 May 2018 16:00:00 GMT',
        reset_at  => 1525363200,
    },
    '->rate_limit from latest response'
);

$rate_limit_headers{'RateLimit-Reset'} = time2str( time + 120 );
_reset( _response( 429,{ error => { message => 'Rate limit exceeded' } },%rate_limit_headers ) );
throws_ok(
    sub { $Pro->api_get( '/payments/PM123' ) },
    'Business::GoCardless::Exception',
    'not retried if ratelimit-reset is more than max_retry_wait away'
);
is( $@->code,429,' ... with code' );
is( scalar( @requests ),1,' ... only one request made' );
is( $Pro->rate_limit->{remaining},0,' ... rate_limit updated' );

note( "DELETE" );

_reset( _response( 200,{ customers => { id => 'CU123' } } ) );
cmp_deeply(
    scalar( $Pro->api_delete( '/customers/CU123' ) ),
    { customers => { id => 'CU123' } },
    '->api_delete'
);
is( $requests[0]->method,'DELETE',' ... sends DELETE' );
like( $requests[0]->uri,qr!/customers/CU123$!,' ... to the resource' );

_reset( _response( 204 ) );
cmp_deeply( scalar( $Pro->api_delete( '/customers/CU123' ) ),{},'204 No Content returns empty hash' );

note( "Errors" );

_reset( _error( 422,'invalid_state',
    { reason => 'mandate_is_inactive',message => 'The mandate is inactive' },
    { reason => 'another_reason',message => 'Another reason' },
) );

throws_ok(
    sub { $Pro->api_post( '/payments',{} ) },
    'Business::GoCardless::Exception',
    'error response'
);

my $E = $@;
is( $E->code,422,' ... code' );
is( $E->type,'invalid_state',' ... type' );
is( $E->request_id,'REQ123',' ... request_id' );
like( $E->documentation_url,qr/invalid_state$/,' ... documentation_url' );
is( scalar( @{ $E->errors } ),2,' ... errors' );
cmp_deeply( [ $E->reasons ],[ qw/ mandate_is_inactive another_reason / ],' ... reasons' );
ok( $E->has_reason( 'mandate_is_inactive' ),' ... has_reason' );
ok( ! $E->has_reason( 'nope' ),' ... ! has_reason' );
ok( ! $E->conflicting_resource_id,' ... ! conflicting_resource_id' );
like( $E->message,qr/An error \(invalid_state\) \/ The mandate is inactive/,' ... message' );

_reset( _error( 422,'validation_failed',{ field => 'given_name',message => 'Jøhñ is invalid' } ) );
throws_ok(
    sub { $Pro->api_post( '/customers',{} ) },
    'Business::GoCardless::Exception',
    'error response with wide chars'
);
is( $@->errors->[0]{message},'Jøhñ is invalid',' ... decoded as characters' );

note( "v1 API" );

_reset( _response( 503 ) );
throws_ok(
    sub { $Client->api_post( '/bills',{} ) },
    'Business::GoCardless::Exception',
    'v1 requests are not retried'
);
is( scalar( @requests ),1,' ... only one request made' );
ok( ! $requests[0]->header( 'Idempotency-Key' ),' ... no Idempotency-Key' );

done_testing();

# vim: ts=4:sw=4:et
