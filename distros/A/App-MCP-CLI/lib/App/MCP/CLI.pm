package App::MCP::CLI;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf8

=head1 NAME

App::MCP::CLI - Command line interface for MCP servers

=head1 VERSION

Version v0.0.1

=head1 SYNOPSIS

    # Install and run via the bundled script
    mcpcli list
    mcpcli call <tool_name> [key=value ...]
    mcpcli interactive --server myserver

=cut

use App::Cmd::Setup -app;

sub plugin_search_path { 'App::MCP::CLI::Command' }

sub global_opt_spec {
    my ($class) = @_;
    return (
        $class->SUPER::global_opt_spec(),
        [ 'version|V', 'print version and exit' ],
    );
}

=head1 DESCRIPTION

C<App::MCP::CLI> is a Perl implementation of a command-line client for servers
that implement the B<Model Context Protocol (MCP)>, a JSON-RPC 2.0-based protocol
for exposing callable "tools" to AI agents and other automation clients.

The distribution provides five sub-commands:

=over 4

=item * B<list> - enumerate all tools advertised by an MCP server.

=item * B<call> - invoke a specific tool, passing arguments inline or through
an interactive prompt when none are supplied.

=item * B<interactive> (alias: B<chat>) - start an agent-style REPL that routes
natural-language queries through a local LLM (currently Ollama) to the appropriate
MCP tool and streams the results back.

=item * B<servers> - show the servers defined in the configuration file.

=item * B<version> - print the installed version.

=back

Both stdio servers and HTTP/SSE servers are supported by every command that
talks to a server (C<list>, C<call>, C<chat>), through the shared
L<App::MCP::CLI::Client>.

=head1 CONFIGURATION

Sub-command options (server path, LLM provider, model, config file) are
documented under each command's C<--help> output. See also
L<App::MCP::CLI::Command::interactive> for the JSON configuration file format.

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI::Command::list>

=item * L<App::MCP::CLI::Command::call>

=item * L<App::MCP::CLI::Command::interactive>

=item * L<App::MCP::CLI::Command::servers>

=item * L<App::MCP::CLI::Client>

=item * L<App::MCP::CLI::Config>

=item * L<App::Cmd> - the framework used to dispatch sub-commands.

=item * MCP specification: L<https://modelcontextprotocol.io/specification>

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

    perldoc App::MCP::CLI

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

1; # End of App::MCP::CLI
