package # hide from PAUSE
    MyBlog;

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

use Catalyst qw(
    -Debug
    ConfigLoader
    Static::Simple

    Authentication
    Authentication::Store::DBIC
    Authentication::Credential::HTTP
);

our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in MyBlog.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'MyBlog' );

# Start the application
__PACKAGE__->setup;

1;
