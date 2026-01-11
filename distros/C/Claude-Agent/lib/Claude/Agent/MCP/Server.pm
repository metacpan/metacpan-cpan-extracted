package Claude::Agent::MCP::Server;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'name!'    => Str,
    'tools'    => sub { [] },
    'version'  => sub { '1.0.0' },
    'type'     => sub { 'sdk' };

=head1 NAME

Claude::Agent::MCP::Server - SDK MCP server configuration

=head1 SYNOPSIS

    use Claude::Agent qw(tool create_sdk_mcp_server);

    my $calc = tool(
        'calculate',
        'Perform basic arithmetic',
        {
            type       => 'object',
            properties => {
                a         => { type => 'number' },
                b         => { type => 'number' },
                operation => { type => 'string', enum => ['add', 'subtract', 'multiply', 'divide'] },
            },
            required => ['a', 'b', 'operation'],
        },
        sub {
            my ($args) = @_;
            my ($a, $b, $op) = @{$args}{qw(a b operation)};
            my $result = $op eq 'add'      ? $a + $b
                       : $op eq 'subtract' ? $a - $b
                       : $op eq 'multiply' ? $a * $b
                       : $op eq 'divide'   ? ($b != 0 ? $a / $b : 'Error: division by zero')
                       :                     'Error: unknown operation';
            return { content => [{ type => 'text', text => "Result: $result" }] };
        }
    );

    my $server = create_sdk_mcp_server(
        name    => 'math',
        tools   => [$calc],
        version => '1.0.0',
    );

    # Tools are named: mcp__math__calculate

=head1 DESCRIPTION

Defines an SDK MCP server that runs tool handlers locally in your Perl process.

When you pass an SDK server to C<mcp_servers> in the options, the SDK:

1. Creates a Unix socket to communicate with child processes
2. Spawns a lightweight MCP server process (SDKRunner)
3. Passes the runner to the CLI as a stdio MCP server
4. When the CLI calls a tool, the runner forwards it via the socket
5. Your handler executes and the result flows back

This allows your tools to access your application's state, databases,
and APIs while being fully integrated with Claude's tool system.

=head2 ATTRIBUTES

=over 4

=item * name - Server name (used in tool naming: mcp__<name>__<tool>)

=item * tools - ArrayRef of L<Claude::Agent::MCP::ToolDefinition> objects

=item * version - Server version (default: '1.0.0')

=item * type - Always 'sdk' for SDK servers

=back

=head2 METHODS

=head3 to_hash

    my $hash = $server->to_hash();

Convert the server configuration to a hash for JSON serialization.

=cut

sub to_hash {
    my ($self) = @_;
    return {
        type    => $self->type,
        name    => $self->name,
        version => $self->version,
        tools   => [ map { $_->to_hash } @{$self->tools} ],
    };
}

=head3 get_tool

    my $tool = $server->get_tool($tool_name);

Get a tool definition by name.

=cut

sub get_tool {
    my ($self, $tool_name) = @_;

    return unless defined $tool_name && length $tool_name;

    for my $tool (@{$self->tools}) {
        return $tool if $tool->name eq $tool_name;
    }

    return;
}

=head3 tool_names

    my $names = $server->tool_names();

Get the full MCP tool names for all tools in this server.

=cut

sub tool_names {
    my ($self) = @_;
    return [ map { 'mcp__' . $self->name . '__' . $_->name } @{$self->tools} ];
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
