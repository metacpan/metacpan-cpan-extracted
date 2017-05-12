package TestApp;

use strict;
use warnings;

use FindBin;
use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use Catalyst qw/ConfigLoader/;

our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in TestApp.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
		name => 'TestApp',
		home => $FindBin::Bin,
		file => $FindBin::Bin . '/conf'
);

# Start the application
__PACKAGE__->setup;

sub backend_base_url {
		my $proto = shift;

		return "http://localhost:3500/";
}


=head1 NAME

TestApp - Catalyst based application

=head1 SYNOPSIS

    script/testapp_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<TestApp::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Toru Yamaguchi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
