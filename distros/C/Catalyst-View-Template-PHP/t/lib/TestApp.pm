package TestApp;
use Moose;
use namespace::autoclean;
use Carp;

use Catalyst::Runtime 5.80;
use Cwd;
use FindBin;
use Config;
use File::Copy;
use Time::HiRes;
use YAML;
use utf8;
$| = 1;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory

use Catalyst qw/
    ConfigLoader

    Session
    Session::Store::File
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in polyglot.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'Polyglot',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
);

# Start the application
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
(*STDOUT)->autoflush(1);
(*STDERR)->autoflush(1);
$APP::DIR = Cwd::getcwd();
__PACKAGE__->setup();

1;
