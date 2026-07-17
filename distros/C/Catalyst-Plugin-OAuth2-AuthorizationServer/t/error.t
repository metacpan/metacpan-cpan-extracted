use v5.36;
use Test::More;
use Test::Fatal;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Error';
require_ok($class);

# defaults
my $e = $class->new( error => 'invalid_request' );
is( $e->error,       'invalid_request', 'error attr' );
is( $e->http_status, 400,               'default http_status is 400' );
is( $e->error_description, undef,        'description optional' );

# to_response shapes the RFC envelope, omitting undef fields
my ( $body, $status ) = $e->to_response;
is_deeply( $body, { error => 'invalid_request' }, 'envelope has just error' );
is( $status, 400, 'status from attr' );

my ( $body2 ) = $class->new(
    error             => 'invalid_client_metadata',
    error_description => 'redirect_uris too many',
    http_status       => 400,
)->to_response;
is_deeply(
    $body2,
    { error => 'invalid_client_metadata', error_description => 'redirect_uris too many' },
    'envelope includes description when set'
);

# throw dies with a blessed instance
my $thrown = exception {
    $class->throw( error => 'too_many_requests', http_status => 429 );
};
isa_ok( $thrown, $class, 'throw dies with an instance' );
is( $thrown->http_status, 429, 'thrown status preserved' );

done_testing;
