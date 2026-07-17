package Catalyst::Plugin::MCP::Server;
use v5.36;
use Moo;
use Scalar::Util qw/blessed/;
use namespace::clean;

our $VERSION = '0.003';

has protocol_versions => (
    is      => 'ro',
    default => sub { ['2025-06-18'] },
);

has server_info => (
    is      => 'ro',
    default => sub { { name => 'mcp-server', version => __PACKAGE__->VERSION } },
);

has _providers => ( is => 'ro', default => sub { {} } );

sub BUILD ( $self, $args ) {
    die "protocol_versions must be a non-empty arrayref\n"
        unless @{ $self->protocol_versions };
}

my %ROLE_FOR_KIND = (
    resources => 'Catalyst::Plugin::MCP::Role::ResourceProvider',
    prompts   => 'Catalyst::Plugin::MCP::Role::PromptProvider',
    tools     => 'Catalyst::Plugin::MCP::Role::ToolProvider',
);

sub register_provider ( $self, $obj ) {
    die "MCP provider must be a blessed object\n" unless blessed $obj;
    my $matched = 0;
    for my $kind ( sort keys %ROLE_FOR_KIND ) {
        next unless $obj->DOES( $ROLE_FOR_KIND{$kind} );
        die "MCP provider of kind '$kind' already registered\n"
            if $self->_providers->{$kind};
        $self->_providers->{$kind} = $obj;
        $matched++;
    }
    die "MCP provider consumes none of the provider roles\n" unless $matched;
    return $self;
}

sub capabilities ( $self ) {
    my %caps;
    $caps{$_} = {} for keys %{ $self->_providers };
    return \%caps;
}

sub _negotiate_version ( $self, $requested ) {
    my @supported = @{ $self->protocol_versions };
    if ( defined $requested ) {
        return $requested if grep { $_ eq $requested } @supported;
    }
    return $supported[0];
}

sub _initialize ( $self, $params ) {
    my $requested = ref $params eq 'HASH' ? $params->{protocolVersion} : undef;
    return {
        protocolVersion => $self->_negotiate_version($requested),
        capabilities    => $self->capabilities,
        serverInfo      => $self->server_info,
    };
}

sub handlers ( $self ) {
    my %h = (
        'initialize'                => sub ($params) { $self->_initialize($params) },
        'ping'                      => sub ($params) { return {} },
        'notifications/initialized' => sub ($params) { return undef },
    );

    if ( $self->_providers->{resources} ) {
        $h{'resources/list'} =
            sub ($params) { $self->_resources_list($params) };
        $h{'resources/templates/list'} =
            sub ($params) { $self->_resources_templates($params) };
        $h{'resources/read'} =
            sub ($params) { $self->_resources_read($params) };
    }
    if ( $self->_providers->{prompts} ) {
        $h{'prompts/list'} = sub ($params) { $self->_prompts_list($params) };
        $h{'prompts/get'}  = sub ($params) { $self->_prompts_get($params) };
    }
    if ( $self->_providers->{tools} ) {
        $h{'tools/list'} = sub ($params) { $self->_tools_list($params) };
        $h{'tools/call'} = sub ($params) { $self->_tools_call($params) };
    }

    return \%h;
}

sub _cursor ( $self, $params ) {
    return ref $params eq 'HASH' ? $params->{cursor} : undef;
}

sub _resources_list ( $self, $params ) {
    return $self->_providers->{resources}->list( $self->_cursor($params) );
}

sub _resources_templates ( $self, $params ) {
    return $self->_providers->{resources}->templates;
}

sub _resources_read ( $self, $params ) {
    my $uri = ref $params eq 'HASH' ? $params->{uri} : undef;
    die { code => -32602, message => 'Invalid params: uri is required' }
        unless defined $uri && length $uri;
    my $out = $self->_providers->{resources}->read($uri);
    die { code => -32002, message => 'Resource not found', data => { uri => $uri } }
        unless defined $out;
    return $out;
}

sub _prompts_list ( $self, $params ) {
    return $self->_providers->{prompts}->list( $self->_cursor($params) );
}

sub _prompts_get ( $self, $params ) {
    my $name = ref $params eq 'HASH' ? $params->{name} : undef;
    die { code => -32602, message => 'Invalid params: name is required' }
        unless defined $name && length $name;
    my $raw_args = ref $params eq 'HASH' ? $params->{arguments} : undef;
    die { code => -32602, message => 'Invalid params: arguments must be an object' }
        if defined $raw_args && ref $raw_args ne 'HASH';
    my $args = $raw_args // {};
    my $out = $self->_providers->{prompts}->get( $name, $args );
    die { code => -32602, message => 'Unknown prompt', data => { name => $name } }
        unless defined $out;
    return $out;
}

sub _tools_list ( $self, $params ) {
    return $self->_providers->{tools}->list( $self->_cursor($params) );
}

sub _tools_call ( $self, $params ) {
    my $name = ref $params eq 'HASH' ? $params->{name} : undef;
    die { code => -32602, message => 'Invalid params: name is required' }
        unless defined $name && length $name;
    my $raw_args = ref $params eq 'HASH' ? $params->{arguments} : undef;
    die { code => -32602, message => 'Invalid params: arguments must be an object' }
        if defined $raw_args && ref $raw_args ne 'HASH';
    my $args = $raw_args // {};

    # Protocol error if the tool is not advertised. The unpaginated list must
    # enumerate every tool (see the ToolProvider POD).
    my $list  = $self->_providers->{tools}->list(undef);
    my @names = map { $_->{name} } @{ $list->{tools} // [] };
    die { code => -32602, message => 'Unknown tool', data => { name => $name } }
        unless grep { defined $_ && $_ eq $name } @names;

    # Execution failures are normal results carrying isError, not exceptions.
    return $self->_providers->{tools}->call( $name, $args );
}

=head1 NAME

Catalyst::Plugin::MCP::Server - Model Context Protocol engine

=head1 SYNOPSIS

    my $engine = Catalyst::Plugin::MCP::Server->new(
        server_info => { name => 'myapp', version => '1.0' },
    );
    $engine->register_provider( $tools );
    my $handlers = $engine->handlers;    # verb name => sub ($params)

=head1 DESCRIPTION

The protocol engine behind L<Catalyst::Plugin::MCP>: it owns the MCP (revision
2025-06-18) lifecycle, capability advertisement, and verb routing, and knows
nothing about your domain: you supply providers.

It also knows nothing about Catalyst or HTTP. The engine maps verb names to
plain coderefs; binding those to a transport is the caller's job.
L<Catalyst::Plugin::MCP> is that binding, and constructs a fresh engine per
request so no state leaks between requests.

=head1 METHODS

=head2 new( %args )

=over

=item protocol_versions

Arrayref of supported MCP revisions, newest-first; defaults to
C<['2025-06-18']>. The first entry is the preferred version, returned when a
client asks for one that is not supported. Dies if empty.

=item server_info

Hashref advertised as C<serverInfo> at C<initialize>; defaults to
C<< { name => 'mcp-server', version => $VERSION } >>. Applications should set
their own name and version.

=back

=head2 register_provider( $obj )

Register a blessed object consuming one or more of the provider roles
(L<Catalyst::Plugin::MCP::Role::ResourceProvider>,
L<Catalyst::Plugin::MCP::Role::PromptProvider>,
L<Catalyst::Plugin::MCP::Role::ToolProvider>). An object consuming several
roles is registered once per kind. Returns the engine, so calls chain.

Dies if C<$obj> is not blessed, consumes none of the roles, or is of a kind
already registered: one provider per kind.

=head2 capabilities

Return the C<capabilities> hashref for C<initialize>: a key per registered
provider kind. Kinds with no registered provider are not advertised, and their
verbs are not routed.

=head2 handlers

Return a hashref of MCP verb name to C<< sub ($params) >>. C<initialize>,
C<ping>, and C<notifications/initialized> are always present; the resource,
prompt, and tool verbs appear only for registered kinds.

A handler returns its result, or C<undef> for a notification (nothing to send
back). To signal a JSON-RPC error it dies with a hashref of C<code>, C<message>,
and optional C<data>, using C<-32602> for bad params and unknown tool or prompt
names, C<-32002> for a resource that does not exist. Note that a tool that runs
and B<fails> is not an error here: that is a normal result carrying
C<< isError => 1 >>, per L<Catalyst::Plugin::MCP::Role::ToolProvider>.

=head1 AUTHOR

Mike Whitaker <mike@altrion.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License, as distributed with Perl.

=cut

1;
