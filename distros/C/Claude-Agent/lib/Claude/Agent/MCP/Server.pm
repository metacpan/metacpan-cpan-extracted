package Claude::Agent::MCP::Server;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::MCP::Server',
        'name:Str:required',
        'tools:ArrayRef:default([])',
        q{version:Str:default('1.0.0')},
        'type:Str:readonly:default(sdk)',
    );
}

sub to_hash {
    my ($self) = @_;
    return {
        type    => $self->type,
        name    => $self->name,
        version => $self->version,
        tools   => [ map { $_->to_hash } @{$self->tools} ],
    };
}

sub to_cli_config {
    my ($self) = @_;
    return {
        type => 'sdk',
        name => $self->name,
    };
}

sub get_tool {
    my ($self, $tool_name) = @_;

    return unless defined $tool_name && length $tool_name;

    for my $tool (@{$self->tools}) {
        return $tool if $tool->name eq $tool_name;
    }

    return;
}

sub tool_names {
    my ($self) = @_;
    return [ map { 'mcp__' . $self->name . '__' . $_->name } @{$self->tools} ];
}

1;

__END__

=head1 NAME

Claude::Agent::MCP::Server - An MCP server that runs inside your process

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

=head1 DESCRIPTION

A set of L<Claude::Agent::MCP::ToolDefinition> objects served to the CLI
over the SDK control channel: the CLI sends each MCP request as a
C<mcp_message> control request and L<Claude::Agent::MCP::SDKBridge>
answers it in this process. Nothing is spawned. The tools are named
C<mcp__E<lt>nameE<gt>__E<lt>toolE<gt>>; list them in C<allowed_tools> or
they will prompt for permission.

=head1 ATTRIBUTES

=head2 name

The server's name. Required.

=head2 tools

ArrayRef of L<Claude::Agent::MCP::ToolDefinition>.

=head2 version

Reported to the CLI in the MCP handshake. Default C<1.0.0>.

=head2 type

Always C<sdk>. Read only.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 to_hash

    my $hash = $server->to_hash;

C<{ type, name, version, tools }> with each tool's C<to_hash>.

=head2 to_cli_config

    my $config = $server->to_cli_config;

C<{ type =E<gt> 'sdk', name =E<gt> $name }>: the entry written to
C<--mcp-config>, which tells the CLI to route the server's requests back
over the control channel.

=head2 get_tool

    my $tool = $server->get_tool($tool_name);

The tool with that (unprefixed) name, or undef.

=head2 tool_names

    my $names = $server->tool_names;

ArrayRef of the full C<mcp__server__tool> names.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
