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
                +CatalystX::Features::Plugin::ConfigLoader/;

__PACKAGE__->config(
    name => 'TestApp',
    'CatalystX::Features' => {
        'backend_class' => 'TestBackendClass',
        'feature_class' => 'TestFeatureClass',
    },
   );

# Start the application
__PACKAGE__->setup();

1;
