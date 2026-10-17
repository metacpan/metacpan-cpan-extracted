package App::MCP::CLI::Command::list;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use App::MCP::CLI -command;

use Text::Table::Tiny qw(generate_table);
use App::MCP::CLI::Client;
use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

=encoding utf8

=head1 NAME

App::MCP::CLI::Command::list - List all tools available on an MCP server

=head1 VERSION

This module is distributed as part of L<App::MCP::CLI> v0.0.1.

=head1 SYNOPSIS

    # Print a table of every tool the server exposes
    mcpcli list --server perl-math-server

    # The only configured server is used when --server is omitted
    mcpcli list

    # Use a script, a raw command, or an SSE URL instead of a config name
    mcpcli list --server ./stdio_server.pl
    mcpcli list --server "node server.js"
    mcpcli list --server http://localhost:8080/sse

=head1 DESCRIPTION

C<App::MCP::CLI::Command::list> implements the C<list> sub-command of the
C<mcpcli> application. It connects to the MCP server over stdio or HTTP/SSE
(through L<App::MCP::CLI::Client>), completes the C<initialize> handshake,
sends C<tools/list> (following pagination), and renders the resulting tool
catalogue as a plain ASCII table using L<Text::Table::Tiny>.

The table has two columns:

=over 4

=item * B<Tool Name> - the C<name> field from the tool descriptor.

=item * B<Description> - the C<description> field, or C<N/A> when absent.

=back

If the server returns an empty tool list the message C<No tools found on the
server.> is printed instead.

=head1 USAGE

    mcpcli list [--server <name|path|url|command>] [--config <file>] [--timeout <seconds>]

=head1 OPTIONS

=over 4

=item C<--server|-s> I<name>

Server name from the config file, a C<.pl> script, a URL, or a command. May be
omitted when the config file defines exactly one server.

=item C<--config|-c> I<path>

Path to the JSON configuration file. See L<App::MCP::CLI::Config>.

=item C<--timeout|-t> I<seconds>

How long to wait for the server (default 30; C<0> waits forever).

=back

=head1 EXIT STATUS

C<0> on success, C<1> if the server could not be started or reached, did not
answer in time, or the configuration is invalid. Errors are printed to STDERR.

=head1 INTERNAL METHODS

=head2 opt_spec

Defines the command-line option specification passed to L<Getopt::Long::Descriptive>
via L<App::Cmd>.

=cut

sub opt_spec {
    return (
        [ 'server|s=s',  'server name, script path, URL or command'            ],
        [ 'config|c=s',  'path to config JSON file'                            ],
        [ 'timeout|t=i', 'seconds to wait for the server (0 = forever)',
                         { default => 30 }                                      ],
    );
}

=head2 description

Returns a one-line description used in the top-level C<mcpcli help> listing.

=cut

sub description { 'List all available tools provided by the MCP server' }

=head2 abstract

Returns the same one-line description for the L<App::Cmd> abstract slot.

=cut

sub abstract    { 'List all available tools provided by the MCP server' }

=head2 execute( $opt, $args )

Main entry point. Connects to the MCP server, retrieves the tool list, and
prints the ASCII table (or a "none found" notice).

=cut

sub execute {
    my ($self, $opt, $args) = @_;

    my $tools = eval {
        my $config_data       = load_config($opt->config);
        my ($cmd, $url, $env) = resolve_server_cmd($config_data, $opt->server);

        my $client = App::MCP::CLI::Client->new(
            cmd => $cmd, url => $url, env => $env, timeout => $opt->timeout,
        );
        $client->connect;

        my $list = eval { $client->list_tools };
        my $err  = $@;
        $client->close;
        die $err if $err;
        $list;
    };

    if (my $err = $@) {
        $err .= "\n" unless $err =~ /\n\z/;
        print STDERR "Error: $err";
        exit 1;
    }

    if (!@$tools) {
        print "No tools found on the server.\n";
        return;
    }

    my @rows = (['Tool Name', 'Description']);
    foreach my $tool (@$tools) {
        push @rows, [ $tool->{name} // '', $tool->{description} // 'N/A' ];
    }

    print "\nAvailable MCP Tools:\n";
    print generate_table(
        rows       => \@rows,
        header_row => 1,
        style      => 'classic'), "\n";
}

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI>

=item * L<App::MCP::CLI::Command::call>

=item * L<App::MCP::CLI::Command::interactive>

=item * L<Text::Table::Tiny>

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

1; # End of App::MCP::CLI::Command::list
