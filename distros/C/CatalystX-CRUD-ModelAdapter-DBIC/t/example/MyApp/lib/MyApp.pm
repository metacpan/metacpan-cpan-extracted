package MyApp;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in MyApp.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'MyApp' );

# Start the application
__PACKAGE__->setup;

# Class::C3 used by Controllers subclassing CatalystX::CRUD::Controller
# so that multiple inheritance from ::REST controller works correctly.
use Class::C3;

# need to call this just once after setup() is done.
Class::C3::initialize();

sub error404 {
    my ($c) = @_;
    $c->response->status(404);
    $c->response->body("Sorry, resource not found");

}

=head1 NAME

MyApp - Catalyst based application

=head1 SYNOPSIS

    script/myapp_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MyApp::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Peter Karman

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
