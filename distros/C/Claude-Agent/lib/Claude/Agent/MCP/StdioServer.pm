package Claude::Agent::MCP::StdioServer;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::MCP::StdioServer',
        'command:Str:required',
        'args:ArrayRef:default([])',
        'env:HashRef:default({})',
        'type:Str:readonly:default(stdio)',
    );
}

sub BUILD {
    my ($self) = @_;

    die "Command must be absolute path" unless $self->command =~ m{^/};
    require Cwd;
    my $canon = Cwd::abs_path($self->command);
    die "Invalid command path" unless $canon && $canon =~ m{^/};

    for my $arg (@{$self->args}) {
        next unless defined $arg;
        die "Invalid arg: contains null byte" if $arg =~ /\0/;
        die "Invalid arg: contains shell metacharacters"
            if $arg =~ /[`\$\(\)\{\};\|<>\\\n\r]/;
    }

    for my $key (keys %{$self->env}) {
        die "Invalid env var name '$key': must match [A-Za-z_][A-Za-z0-9_]*"
            unless $key =~ /^[A-Za-z_][A-Za-z0-9_]*$/;
        my $value = $self->env->{$key};
        next unless defined $value;
        die "Invalid env var value for '$key': contains null byte" if $value =~ /\0/;
        die "Invalid env var value for '$key': contains control characters"
            if $value =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    }
    return;
}

sub to_hash {
    my ($self) = @_;
    return {
        type    => 'stdio',
        command => $self->command,
        args    => $self->args,
        env     => $self->env,
    };
}

1;

__END__

=head1 NAME

Claude::Agent::MCP::StdioServer - An external MCP server the CLI starts

=head1 SYNOPSIS

    use Claude::Agent::MCP::StdioServer;

    my $server = Claude::Agent::MCP::StdioServer->new(
        command => '/usr/bin/npx',
        args    => ['-y', '@modelcontextprotocol/server-filesystem', '/tmp'],
        env     => { API_KEY => $key },
    );

=head1 DESCRIPTION

Configuration for an MCP server the CLI runs as a child process and talks
to over its standard streams. The command and arguments are passed to the
CLI as given: build them from trusted values only.

The constructor refuses a relative command, an argument containing a null
byte or a shell metacharacter, an environment name that is not a POSIX
identifier, and an environment value containing a control character.

=head1 ATTRIBUTES

=head2 command

Absolute path of the executable. Required.

=head2 args

ArrayRef of arguments.

=head2 env

HashRef of environment variables for the server.

=head2 type

Always C<stdio>. Read only.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 to_hash

    my $hash = $server->to_hash;

C<{ type, command, args, env }>, the C<--mcp-config> entry.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
