package RRDGraphTest003;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use base qw/Catalyst/;
use Catalyst qw/-Debug
                Static::Simple/;
our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in ap1.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'RRDGraphTest003' );

# Start the application
__PACKAGE__->setup();


1;
