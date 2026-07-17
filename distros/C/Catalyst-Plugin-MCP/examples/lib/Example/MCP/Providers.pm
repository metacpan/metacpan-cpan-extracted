package Example::MCP::Providers;
use v5.36;

package Example::MCP::Providers::Tools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';

    sub list ( $self, $cursor = undef ) {
        return { tools => [
            { name => 'echo', description => 'Echo back the msg argument' },
        ] };
    }

    sub call ( $self, $name, $args ) {
        return { content => [
            { type => 'text', text => 'echo: ' . ( $args->{msg} // '' ) },
        ] };
    }
}

package Example::MCP::Providers::Resources {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ResourceProvider';

    sub list ( $self, $cursor = undef ) {
        return { resources => [ { uri => 'mem://greeting', name => 'greeting' } ] };
    }

    sub templates ( $self ) { return { resourceTemplates => [] } }

    sub read ( $self, $uri ) {
        return undef unless $uri eq 'mem://greeting';
        return { contents => [ { uri => $uri, text => 'hello from the example resource' } ] };
    }
}

1;
