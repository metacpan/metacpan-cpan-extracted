package Claude::Agent::MCP::StdioServer;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    'command!' => Str,
    'args'     => sub { [] },
    'env'      => sub { {} },
    'type'     => sub { 'stdio' };

sub BUILD {
    my ($self) = @_;
    die "Command must be absolute path" unless $self->command =~ m{^/};
    require Cwd;
    my $canon = Cwd::abs_path($self->command);
    die "Invalid command path" unless $canon && $canon =~ m{^/};

    # Validate args to prevent command injection via shell metacharacters
    # Args are passed to execve() not through shell, but some programs may
    # interpret special characters. Reject obviously dangerous patterns.
    for my $arg (@{$self->args}) {
        next unless defined $arg;
        # Reject null bytes which could truncate arguments
        die "Invalid arg: contains null byte" if $arg =~ /\0/;
        # Reject shell metacharacters that could be dangerous if passed to subshells
        die "Invalid arg: contains shell metacharacters"
            if $arg =~ /[`\$\(\)\{\};\|<>\\\n\r]/;
    }

    # Validate environment variables to prevent injection attacks
    # Environment variable values can affect child process behavior
    for my $key (keys %{$self->env}) {
        # Validate environment variable names: must be alphanumeric with underscores
        # Standard POSIX convention, reject special characters that could cause issues
        die "Invalid env var name '$key': must match [A-Za-z_][A-Za-z0-9_]*"
            unless $key =~ /^[A-Za-z_][A-Za-z0-9_]*$/;

        my $value = $self->env->{$key};
        next unless defined $value;

        # Reject null bytes which could truncate values or cause security issues
        die "Invalid env var value for '$key': contains null byte" if $value =~ /\0/;

        # Reject control characters (except tab, which is sometimes legitimate)
        # Control chars could affect terminal behavior or be used for injection
        die "Invalid env var value for '$key': contains control characters"
            if $value =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    }

    return;
}

=head1 NAME

Claude::Agent::MCP::StdioServer - Stdio MCP server configuration

=head1 DESCRIPTION

Configuration for an external MCP server process.

B<Security note:> The command and args are passed directly to the Claude CLI
for execution. Ensure you only use trusted values - never construct a
StdioServer from untrusted user input without validation, as this could
enable command injection attacks.

=head2 ATTRIBUTES

=over 4

=item * command - Command to run (should be a trusted executable path)

=item * args - ArrayRef of command arguments

=item * env - HashRef of environment variables

=item * type - Always 'stdio'

=back

=head2 METHODS

=head3 to_hash

    my $hash = $server->to_hash();

Convert the server configuration to a hash for JSON serialization.

=cut

sub to_hash {
    my ($self) = @_;
    return {
        type    => 'stdio',
        command => $self->command,
        args    => $self->args,
        env     => $self->env,
    };
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
