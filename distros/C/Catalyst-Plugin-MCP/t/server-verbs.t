use v5.36;
use Test::More;
use Test::Fatal;
use Catalyst::Plugin::MCP::Server;

# --- stub providers that record their args and exercise every path ------
package RecTools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';
    has seen => ( is => 'ro', default => sub { {} } );
    sub list ( $self, $cursor = undef ) {
        $self->seen->{list_cursor} = $cursor;
        return { tools => [ { name => 'echo' } ], nextCursor => 'NEXT' };
    }
    sub call ( $self, $name, $args ) {
        $self->seen->{call} = [ $name, $args ];
        return { isError => 1, content => [ { type => 'text', text => 'boom' } ] }
            if $args->{fail};
        return { content => [ { type => 'text', text => "ran $name" } ] };
    }
}
package RecResources {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ResourceProvider';
    sub list      ( $self, $cursor = undef ) { return { resources => [], nextCursor => $cursor } }
    sub templates ( $self )                  { return { resourceTemplates => [ { uriTemplate => 't' } ] } }
    sub read ( $self, $uri ) {
        return undef if $uri eq 'gone://x';
        return { contents => [ { uri => $uri, text => 'hi' } ] };
    }
}
package RecPrompts {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::PromptProvider';
    sub list ( $self, $cursor = undef ) { return { prompts => [], nextCursor => $cursor } }
    sub get ( $self, $name, $args ) {
        return undef if $name eq 'nope';
        return { messages => [ { role => 'user', content => $args } ] };
    }
}
# ------------------------------------------------------------------------

my $tools = RecTools->new;
my $engine = Catalyst::Plugin::MCP::Server->new;
$engine->register_provider($tools);
$engine->register_provider( RecResources->new );
$engine->register_provider( RecPrompts->new );
my $h = $engine->handlers;

# pagination pass-through: cursor in -> provider sees it; nextCursor out
my $list = $h->{'tools/list'}->( { cursor => 'C1' } );
is( $tools->seen->{list_cursor}, 'C1', 'cursor passed to provider list()' );
is( $list->{nextCursor}, 'NEXT', 'nextCursor returned verbatim' );

# resources/list passes the cursor too
is( $h->{'resources/list'}->( { cursor => 'RC' } )->{nextCursor},
    'RC', 'resources/list pass-through cursor' );

# resources/read happy path
is_deeply( $h->{'resources/read'}->( { uri => 'file://a' } ),
    { contents => [ { uri => 'file://a', text => 'hi' } ] },
    'resources/read returns provider contents' );

# resources/read missing uri -> -32602
is( exception { $h->{'resources/read'}->( {} ) }->{code}, -32602,
    'resources/read without uri is -32602' );

# resources/read unknown uri -> -32002
is( exception { $h->{'resources/read'}->( { uri => 'gone://x' } ) }->{code},
    -32002, 'resources/read of unknown uri is -32002' );

# resources/templates happy path
is_deeply( $h->{'resources/templates/list'}->( {} ),
    { resourceTemplates => [ { uriTemplate => 't' } ] },
    'resources/templates/list returns provider templates' );

# prompts/list cursor pass-through
is( $h->{'prompts/list'}->( { cursor => 'PC' } )->{nextCursor},
    'PC', 'prompts/list passes the cursor through to the provider' );

# prompts/get happy + unknown
is_deeply( $h->{'prompts/get'}->( { name => 'p', arguments => { a => 1 } } ),
    { messages => [ { role => 'user', content => { a => 1 } } ] },
    'prompts/get passes name + arguments' );
is( exception { $h->{'prompts/get'}->( { name => 'nope' } ) }->{code},
    -32602, 'unknown prompt is -32602' );
is( exception { $h->{'prompts/get'}->( {} ) }->{code}, -32602,
    'prompts/get without name is -32602' );

# tools/call happy: result returned verbatim, args forwarded
is_deeply( $h->{'tools/call'}->( { name => 'echo', arguments => { x => 1 } } ),
    { content => [ { type => 'text', text => 'ran echo' } ] },
    'tools/call returns the provider result' );
is_deeply( $tools->seen->{call}, [ 'echo', { x => 1 } ],
    'tools/call forwards name + arguments' );

# tools/call execution error: NORMAL result carrying isError, not an exception
my $err_result;
is( exception {
        $err_result = $h->{'tools/call'}->( { name => 'echo', arguments => { fail => 1 } } );
    },
    undef, 'execution failure does not throw' );
is( $err_result->{isError}, 1, 'execution failure rides in isError result' );

# tools/call unknown tool: protocol error -32602
is( exception { $h->{'tools/call'}->( { name => 'ghost' } ) }->{code},
    -32602, 'unknown tool is a -32602 protocol error' );

# tools/call missing name -> -32602
is( exception { $h->{'tools/call'}->( {} ) }->{code}, -32602,
    'tools/call without name is -32602' );

# S1: tools/call with non-hash arguments -> -32602
is( exception { $h->{'tools/call'}->( { name => 'echo', arguments => 'bad' } ) }->{code},
    -32602, 'tools/call with string arguments is -32602' );
is( exception { $h->{'tools/call'}->( { name => 'echo', arguments => [1,2,3] } ) }->{code},
    -32602, 'tools/call with arrayref arguments is -32602' );

# S1: prompts/get with non-hash arguments -> -32602
is( exception { $h->{'prompts/get'}->( { name => 'p', arguments => 'bad' } ) }->{code},
    -32602, 'prompts/get with string arguments is -32602' );
is( exception { $h->{'prompts/get'}->( { name => 'p', arguments => [1,2,3] } ) }->{code},
    -32602, 'prompts/get with arrayref arguments is -32602' );

done_testing;
