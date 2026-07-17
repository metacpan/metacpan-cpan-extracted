use v5.36;
use Test::More;
use Test::Fatal;

# A well-formed tool provider composes and reports its role.
package GoodTools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';
    sub list ( $self, $cursor = undef ) { return { tools => [] } }
    sub call ( $self, $name, $args )    { return { content => [] } }
}

# A resource provider missing read() must fail to compose.
my $bad = exception {
    package BadResources {
        use Moo;
        with 'Catalyst::Plugin::MCP::Role::ResourceProvider';
        sub list      ( $self, $cursor = undef ) { return { resources => [] } }
        sub templates ( $self )                  { return { resourceTemplates => [] } }
        # no read() -> composition should die
    }
};

my $obj = GoodTools->new;
ok( $obj->DOES('Catalyst::Plugin::MCP::Role::ToolProvider'),
    'consuming class DOES the role' );
ok( $bad, 'missing required method (read) fails composition' );
like( $bad, qr/read/, 'failure names the missing method' );

done_testing;
