package App::Mimosa;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst ((
#    '-Debug',
    qw/
    ConfigLoader
    Static::Simple
    AutoCRUD
    Authentication
    Authorization::Roles
    Session
    Session::State::Cookie
    Session::Store::FastMmap
    /)
);

extends 'Catalyst';

our $VERSION = '0.02';
$VERSION = eval $VERSION;

# Defaults

__PACKAGE__->config(
    name                                                     => 'Mimosa',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback              => 1,

    default_view                                             => 'Mason',
    'Plugin::Authentication'                                 => {
        default => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'Minimal',
                users => {
                    petunia => {
                        password => "cUC598",
                    },
                }
            }
        }
}
);


# Start the application
__PACKAGE__->setup();


=head1 NAME

App::Mimosa - Miniature Model Organism Sequence Aligner

=head1 SYNOPSIS

=head2 DEPLOYING

For full details on the deploy options:

    perldoc script/mimosa_deploy.pl

To deploy a Mimosa database:

    perl script/mimosa_deploy.pl

=head2 RUNNING

For full details on the server options:

    perldoc script/mimosa_server.pl

To start Mimosa on port 8888:

    perl script/mimosa_server.pl -p 8888

To start Mimosa on the default port (3000):

    perl script/mimosa_server.pl

You should see something like:

    You can connect to your server at http://localhost:3000

Now you can go to L<http://localhost:3000> and try Mimosa!

=head1 DEPENDENCIES

Mimosa has some non-Perl dependencies. Most notably, the NCBI BLAST command-line
suite of programs. These are detected by attempting to execute

    fastacmd

If it does not exist, then Mimosa will currently not work at all. Future versions
of Mimosa may detect different alignment programs such as BWA.

The above command is also necessary to run the Mimosa test suite.

=head1 SEE ALSO

L<App::Mimosa::Controller::Root>, L<Catalyst>

=head1 AUTHORS

Jonathan "Duke" Leto <jonathan@leto.net>, Rob Buels

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
