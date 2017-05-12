package CPAN::Mini::Inject::REST::Client;

use 5.010;
use strict;
use warnings;
use App::Cmd::Setup -app;
use Config::General qw/ParseConfig/;
use File::HomeDir;
use File::Spec::Functions qw/catfile/;

=head1 NAME

CPAN::Mini::Inject::REST::Client - Command-line client for CPAN::Mini::Inject::REST

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

 mcpani-client <command> <options> <files>
 
 mcpani-client add --host mycpan.local MyModule-0.01.tar.gz

=head1 DESCRIPTION

Provides a command-line client, F<mcpani-client>, to interact with a
L<CPAN::Mini::Inject::REST> API server.

This allows distributions to be remotely uploaded to your CPAN mirror,
and for the contents of your mirror to be queried and downloaded.

See L<mcpani-client> for full documentation on the available commands.

=cut

sub config {
    state $config = {ParseConfig(config_file())};
    return $config;
}

sub config_file {
    my @files = (
        $ENV{MCPANI_CLIENT_CONFIG},
        catfile(File::HomeDir->my_home, '.mcpani-client'),
        '/usr/local/etc/mcpani-client',
        '/etc/mcpani-client',
    );
    
    foreach my $file (grep {defined $_} @files) {
        return $file if -r $file;
    }
}

=head1 AUTHOR

Jon Allen (JJ), C<< <jj at jonalen.info> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jon Allen (JJ).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of CPAN::Mini::Inject::REST::Client
