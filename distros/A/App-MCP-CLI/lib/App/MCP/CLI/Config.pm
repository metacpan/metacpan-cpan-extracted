package App::MCP::CLI::Config;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use File::Spec;
use JSON::MaybeXS;

use Exporter 'import';
our @EXPORT_OK = qw(load_config resolve_server_cmd);

=encoding utf8

=head1 NAME

App::MCP::CLI::Config - Configuration loader and server resolver for App::MCP::CLI

=head1 VERSION

This module is distributed as part of L<App::MCP::CLI> v0.0.1.

=head1 SYNOPSIS

    use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

    # Load config from an explicit path, or auto-discover
    my $config = load_config('/path/to/server_config.json');
    my $config = load_config();   # auto-discovers

    # Resolve a named server to a command array (stdio) or URL (SSE)
    my ($cmd, $url, $env) = resolve_server_cmd($config, 'perl-math-server');

    if ($url) {
        # SSE transport
    }
    else {
        # stdio transport - see App::MCP::CLI::Client, which spawns @$cmd
        # with %$env applied to the child only
    }

=head1 DESCRIPTION

C<App::MCP::CLI::Config> is the shared configuration layer for all
C<App::MCP::CLI> sub-commands. It provides two exported functions:

=over 4

=item * L</load_config> - reads and parses the JSON configuration file,
with automatic discovery of well-known paths when no explicit path is given.

=item * L</resolve_server_cmd> - maps a server name (or bare command string,
script path, or URL) to either a command array for stdio transport or a URL
for SSE transport.

=back

Centralising this logic here means that C<call>, C<list>, C<interactive>, and
any future sub-commands all share identical config-loading and server-resolution
behaviour.

=head1 CONFIGURATION FILE FORMAT

The JSON configuration file has the following top-level structure:

    {
      "confirmTools": true,
      "mcpServers": {
        "perl-math-server": {
          "command": "perl",
          "args": ["stdio_server.pl"],
          "env": { "DEBUG": "1" }
        },
        "remote-server": {
          "url": "http://mcp.example.com/sse"
        }
      }
    }

=head2 mcpServers

A JSON object whose keys are server alias names and whose values are server
descriptor objects. Each descriptor supports the following fields:

=over 4

=item C<command> (string)

The executable to launch when using stdio transport (e.g. C<"perl">,
C<"node">).  Required for stdio servers.

=item C<args> (array of strings)

Additional command-line arguments passed to C<command>
(e.g. C<["stdio_server.pl"]>). Defaults to an empty list.

=item C<env> (object)

A map of environment variable names to values. The entries are passed to the
server subprocess only; they are never set in the C<mcpcli> process itself.

=item C<url> (string)

The SSE endpoint URL for remote servers (e.g.
C<"http://mcp.example.com/sse">). When present, the server is contacted via
HTTP/SSE instead of a local subprocess.

=item C<transport> (string)

Informational (C<"stdio"> or C<"sse">). A server is treated as SSE when it has
a C<url>. C<transport: "sse"> without a C<url> is rejected with an error.

=back

=head2 confirmTools

Optional boolean (default C<true>). When set to C<false>, the
C<interactive>/C<chat> command executes tool calls autonomously without pausing
to ask the user for confirmation.

=head1 AUTO-DISCOVERY

When L</load_config> is called without an argument (or with C<undef>), it
searches for a configuration file in the following locations, in order:

=over 4

=item 1. C<./server_config.json> - in the current working directory.

=item 2. C<./mcp-config.json> - in the current working directory.

=item 3. C<$HOME/.config/mcp-cli/config.json> - XDG-style user config
(C<$USERPROFILE> is used as the home directory on Windows).

=back

If none of these paths exist, C<load_config> returns C<undef> and the
caller must fall back to other means of locating the server (e.g. a bare
C<--server> command string).

=head1 EXPORTS

Nothing is exported by default. The following functions may be imported
explicitly:

    use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

=head1 FUNCTIONS

=head2 load_config

Signature: C<load_config( [$path] )>.

    my $config = load_config();
    my $config = load_config('/path/to/server_config.json');

Loads and parses the JSON configuration file at C<$path>. If C<$path> is
omitted or C<undef>, the auto-discovery sequence described in L</AUTO-DISCOVERY>
is used.

Returns a hashref on success, or C<undef> when no path was given and no
well-known file exists. When a path B<is> given explicitly, a missing or
unreadable file, or invalid JSON, is a fatal error (C<die>), so typos in
C<--config> are never silently ignored. A discovered file that cannot be
parsed only produces a warning on STDERR and C<undef>.

Informational messages are written to STDERR so that STDOUT stays clean for
piping.

=cut

sub load_config {
    my ($config_path) = @_;

    my $json     = JSON::MaybeXS->new(utf8 => 1, allow_nonref => 1);
    my $explicit = defined $config_path && length $config_path;

    # Auto-discover if not explicitly given
    if (!$explicit) {
        my $home = $ENV{HOME} || $ENV{USERPROFILE} || '.';
        my $xdg  = File::Spec->catfile($home, '.config', 'mcp-cli', 'config.json');

        if    (-f 'server_config.json') { $config_path = 'server_config.json' }
        elsif (-f 'mcp-config.json')    { $config_path = 'mcp-config.json'    }
        elsif (-f $xdg)                 { $config_path = $xdg                 }
        else                            { return undef                        }
    }

    die "Config file not found: $config_path\n" if $explicit && !-f $config_path;

    print STDERR "[-] Reading configuration from: $config_path\n";
    open my $fh, '<', $config_path or do {
        die "Could not open config file '$config_path': $!\n" if $explicit;
        warn "[-] Warning: Could not open config file: $!\n";
        return undef;
    };
    my $content = do { local $/; <$fh> };
    close $fh;

    my $data = eval { $json->decode($content) };
    if ($@) {
        (my $err = $@) =~ s/ at \S+ line \d+\.?\s*\z//;
        die "Failed to parse config '$config_path': $err\n" if $explicit;
        warn "[-] Warning: Failed to parse config JSON ($config_path): $err\n";
        return undef;
    }
    return $data;
}

=head2 resolve_server_cmd

Signature: C<resolve_server_cmd( $config, $server_input )>.

    my ($cmd, $url, $env) = resolve_server_cmd($config, 'perl-math-server');
    my ($cmd, $url, $env) = resolve_server_cmd($config, 'http://localhost/sse');
    my ($cmd, $url, $env) = resolve_server_cmd($config, 'perl stdio_server.pl');
    my ($cmd, $url, $env) = resolve_server_cmd($config);   # sole configured server

Resolves C<$server_input> to a transport endpoint. C<$config> is the hashref
returned by L</load_config> (may be C<undef>).

Resolution order:

=over 4

=item 1. If C<$server_input> is empty or C<undef>: when the configuration
defines exactly one server, that server is used; otherwise this is a fatal
error that lists the available names.

=item 2. If C<$config> contains a matching C<mcpServers> entry, that
descriptor is used. A descriptor with a C<url> is an SSE server. One whose
C<transport> is C<sse> but which has no C<url>, or one with neither C<url>
nor C<command>, is a fatal error with an explanatory message.

=item 3. If C<$server_input> looks like an HTTP(S) URL, SSE mode is selected.

=item 4. If C<$server_input> ends in C<.pl> and the file exists, it is run
with the current Perl interpreter (C<$^X>).

=item 5. Otherwise, C<$server_input> is split on whitespace and used as a
raw command list.

=back

Return value is a three-element list C<($cmd, $url, $env)>:

=over 4

=item * For B<stdio> servers: C<$cmd> is an arrayref of command + arguments
suitable for passing to C<IPC::Open2::open2>; C<$url> is C<undef>.

=item * For B<SSE> servers: C<$url> is the endpoint URL string; C<$cmd> is
C<undef>.

=item * C<$env> is a hashref of extra environment variables from the
descriptor's C<env> block (empty when there is none). It is B<not> applied to
the current process; L<App::MCP::CLI::Client> sets it for the spawned server
only, so variables never leak from one server to another.

=back

=cut

sub resolve_server_cmd {
    my ($config_data, $server_input) = @_;

    my $servers = ($config_data && ref $config_data->{mcpServers} eq 'HASH')
                ? $config_data->{mcpServers} : {};

    if (!defined $server_input || $server_input eq '') {
        my @names = sort keys %$servers;
        return resolve_server_cmd($config_data, $names[0]) if @names == 1;

        die "No server specified. Use --server <name|url|command>"
          . (@names ? ". Configured servers: " . join(', ', @names) : '')
          . "\n";
    }

    if (ref $servers->{$server_input} eq 'HASH') {
        my $srv = $servers->{$server_input};
        print STDERR "[-] Resolved server settings for '$server_input' via config file.\n";

        my $env = ref $srv->{env} eq 'HASH' ? { %{ $srv->{env} } } : {};

        return (undef, $srv->{url}, $env) if defined $srv->{url} && length $srv->{url};

        die "Server '$server_input' has transport 'sse' but no 'url'.\n"
            if lc($srv->{transport} // '') eq 'sse';

        die "Server '$server_input' has neither a 'command' nor a 'url'.\n"
            unless defined $srv->{command} && length $srv->{command};

        my $args = ref $srv->{args} eq 'ARRAY' ? $srv->{args} : [];
        return ([$srv->{command}, @$args], undef, $env);
    }

    # Fallback
    if    ($server_input =~ /^https?:\/\//i)             { return (undef, $server_input, {}) }
    elsif ($server_input =~ /\.pl$/ && -f $server_input) { return ([$^X, $server_input], undef, {}) }
    else  { return ([split ' ', $server_input], undef, {}) }
}

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI>

=item * L<App::MCP::CLI::Command::call>

=item * L<App::MCP::CLI::Command::list>

=item * L<App::MCP::CLI::Command::interactive>

=item * L<App::MCP::CLI::Command::servers>

=item * L<App::MCP::CLI::Client>

=item * L<JSON::MaybeXS> - JSON parser used internally.

=item * L<File::Spec> - used for portable config path construction.

=item * MCP specification: L<https://spec.modelcontextprotocol.io/>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-MCP-CLI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/App-MCP-CLI/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MCP::CLI::Config

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/App-MCP-CLI/issues>

=item * Search MetaCPAN

L<http://metacpan.org/dist/App-MCP-CLI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of App::MCP::CLI::Config
