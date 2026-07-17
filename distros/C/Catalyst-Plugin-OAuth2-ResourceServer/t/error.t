use v5.36;
use Test::More;
use Test::Fatal;

my $class = 'Catalyst::Plugin::OAuth2::ResourceServer::Error';
require_ok($class);

# defaults: a bare challenge has no error and is 401
my $bare = $class->new;
is( $bare->error,       undef, 'error optional' );
is( $bare->http_status, 401,   'default http_status 401' );

# an invalid_token error
my $e = $class->new( error => 'invalid_token', error_description => 'bad sig' );
is( $e->error,             'invalid_token', 'error attr' );
is( $e->error_description, 'bad sig',       'description attr' );
is( $e->http_status,       401,             'still 401' );

# insufficient_scope carries scope + 403
my $s = $class->new(
    error => 'insufficient_scope', http_status => 403, scope => 'example:read' );
is( $s->scope,       'example:read', 'scope attr' );
is( $s->http_status, 403,          '403 for scope' );

# throw dies with a blessed instance
my $thrown = exception { $class->throw( error => 'invalid_token' ) };
isa_ok( $thrown, $class, 'throw dies with an instance' );

done_testing;
