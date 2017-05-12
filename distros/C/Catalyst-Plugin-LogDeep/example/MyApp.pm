package MyApp;

use strict;
use warnings;

use Catalyst::Runtime 5.70;
use version;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
	-Debug
	ConfigLoader
	Static::Simple

	LogDeep

/;
our $VERSION = version->new('0.0.4');

# Configure the application.
#
# Note that settings in diet.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
	name              => 'MyApp',
	'Plugin::LogDeep' => {
		-level => [ qw/debug warn error fatal/ ],
	},
);

# Start the application
__PACKAGE__->setup();


=head1 NAME

MyApp - Catalyst based application

=head1 SYNOPSIS

    script/diet_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MyApp::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Ivan Wills,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
