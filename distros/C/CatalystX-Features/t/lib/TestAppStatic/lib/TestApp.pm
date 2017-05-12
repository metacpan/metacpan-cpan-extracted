package TestApp;
use strict;
use warnings;

use Catalyst::Runtime 5.70;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use base qw/Catalyst/;
use Catalyst qw/+CatalystX::Features
                +CatalystX::Features::Lib
                +CatalystX::Features::Plugin::ConfigLoader
                +CatalystX::Features::Plugin::Static::Simple
                /;

__PACKAGE__->config( name => 'TestApp' );

__PACKAGE__->config->{static}->{dirs} = [
'static',
	qr/^(images|html|css)/,
	];

# Start the application
__PACKAGE__->setup();

1;
