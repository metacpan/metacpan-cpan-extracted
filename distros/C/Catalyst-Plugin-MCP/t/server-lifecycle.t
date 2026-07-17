use v5.36;
use Test::More;
use Test::Fatal;
use Catalyst::Plugin::MCP::Server;

# --- stub providers (one kind each) -------------------------------------
package StubTools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';
    sub list ( $self, $cursor = undef ) { return { tools => [] } }
    sub call ( $self, $name, $args )    { return { content => [] } }
}
package StubResources {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ResourceProvider';
    sub list      ( $self, $cursor = undef ) { return { resources => [] } }
    sub templates ( $self )                  { return { resourceTemplates => [] } }
    sub read      ( $self, $uri )            { return undef }
}
# ------------------------------------------------------------------------

# register_provider validates input
my $e = Catalyst::Plugin::MCP::Server->new;
ok( exception { $e->register_provider('not an object') },
    'non-object provider dies' );
ok( exception { $e->register_provider( bless {}, 'Random::Class' ) },
    'object with no provider role dies' );

# capabilities reflect only registered kinds
my $engine = Catalyst::Plugin::MCP::Server->new;
$engine->register_provider( StubTools->new );
is_deeply( $engine->capabilities, { tools => {} },
    'only tools advertised' );
$engine->register_provider( StubResources->new );
is_deeply( $engine->capabilities, { tools => {}, resources => {} },
    'tools + resources advertised' );

# handlers exist for registered kinds + lifecycle, not for prompts
my $h = $engine->handlers;
ok( $h->{initialize},     'initialize handler present' );
ok( $h->{ping},           'ping handler present' );
ok( $h->{'tools/call'},   'tools/call handler present' );
ok( $h->{'resources/read'}, 'resources/read handler present' );
ok( !$h->{'prompts/get'}, 'no prompts handler (none registered)' );

# initialize: echo a supported version
is_deeply(
    $h->{initialize}->( { protocolVersion => '2025-06-18' } ),
    {
        protocolVersion => '2025-06-18',
        capabilities    => { tools => {}, resources => {} },
        serverInfo      => {
            name    => 'mcp-server',
            version => Catalyst::Plugin::MCP::Server->VERSION,
        },
    },
    'initialize echoes a supported protocol version'
);

# The default server_info version tracks $VERSION, so the assertion above cannot
# catch it going undef. Advertising a null version to a client is a real failure.
like( $h->{initialize}->( {} )->{serverInfo}{version},
    qr/\A\d+\.\d+/, 'default serverInfo advertises a real version' );

# initialize: unknown version -> preferred (first) supported
is( $h->{initialize}->( { protocolVersion => '1999-01-01' } )->{protocolVersion},
    '2025-06-18', 'unknown version negotiates down to preferred' );

# ping -> empty object
is_deeply( $h->{ping}->( {} ), {}, 'ping returns {}' );

# S3: empty protocol_versions dies at construction
ok( exception { Catalyst::Plugin::MCP::Server->new( protocol_versions => [] ) },
    'empty protocol_versions dies at construction' );

# S4: registering two providers of the same kind dies
{
    my $dup = Catalyst::Plugin::MCP::Server->new;
    $dup->register_provider( StubTools->new );
    like( exception { $dup->register_provider( StubTools->new ) },
        qr/already registered/, 'duplicate same-kind provider dies with already registered' );
}

done_testing;
