package TestProviders;
use v5.36;

package TestProviders::Tools {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ToolProvider';
    sub list ( $self, $cursor = undef ) {
        return { tools => [ { name => 'echo', description => 'echoes' } ] };
    }
    sub call ( $self, $name, $args ) {
        return { isError => 1, content => [ { type => 'text', text => 'failed' } ] }
            if $args->{fail};
        return { content => [ { type => 'text', text => "echo: " . ( $args->{msg} // '' ) } ] };
    }
}

package TestProviders::Resources {
    use Moo;
    with 'Catalyst::Plugin::MCP::Role::ResourceProvider';
    sub list      ( $self, $cursor = undef ) { return { resources => [ { uri => 'mem://a' } ] } }
    sub templates ( $self )                  { return { resourceTemplates => [] } }
    sub read ( $self, $uri ) {
        return undef unless $uri eq 'mem://a';
        return { contents => [ { uri => $uri, text => 'alpha' } ] };
    }
}

1;
