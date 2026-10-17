package App::MCP::CLI::Command::servers;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use App::MCP::CLI -command;

use Text::Table::Tiny qw(generate_table);
use App::MCP::CLI::Config qw(load_config);

=encoding utf8

=head1 NAME

App::MCP::CLI::Command::servers - List all servers defined in the config file

=head1 VERSION

This module is distributed as part of L<App::MCP::CLI> v0.0.1.

=head1 SYNOPSIS

    # List all configured servers
    mcpcli servers

    # Use a specific config file
    mcpcli servers --config examples/server_config.json

=head1 DESCRIPTION

C<App::MCP::CLI::Command::servers> implements the C<servers> sub-command of
the C<mcpcli> application. It reads the configuration file and prints a table
of all server names and their transport type (stdio or SSE).

=head1 INTERNAL METHODS

=cut

sub description { 'List all servers defined in the configuration file' }
sub abstract    { 'List all servers defined in the configuration file' }

=head2 opt_spec

=cut

sub opt_spec {
    return (
        [ 'config|c=s', 'path to config JSON file' ],
    );
}

=head2 execute( $opt, $args )

Loads the config file and prints a table of server names and transport types.

=cut

sub execute {
    my ($self, $opt, $args) = @_;

    my $config_data = load_config($opt->config);

    if (!$config_data || !$config_data->{mcpServers} || !%{ $config_data->{mcpServers} }) {
        print "No servers found in configuration.\n";
        return;
    }

    my $servers = $config_data->{mcpServers};
    my @rows    = (['Server Name', 'Transport', 'Command / URL']);

    foreach my $name (sort keys %$servers) {
        my $srv = $servers->{$name};

        my ($transport, $endpoint);
        if ($srv->{url} || (($srv->{transport} // '') eq 'sse')) {
            $transport = 'SSE';
            $endpoint  = $srv->{url} // '(transport: sse)';
        } else {
            $transport = 'stdio';
            my @parts  = ($srv->{command} // '');
            push @parts, @{ $srv->{args} // [] };
            $endpoint  = join(' ', @parts);
        }

        push @rows, [$name, $transport, $endpoint];
    }

    print "\nConfigured MCP Servers:\n";
    print generate_table(
        rows       => \@rows,
        header_row => 1,
        style      => 'classic'), "\n";
}

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI>

=item * L<App::MCP::CLI::Command::list>

=item * L<App::MCP::CLI::Command::interactive>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-MCP-CLI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/App-MCP-CLI/issues>.
I will be notified and then you'll automatically be notified of progress on your
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

1; # End of App::MCP::CLI::Command::servers
