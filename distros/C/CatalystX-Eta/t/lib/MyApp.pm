package MyApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.90080;
use open qw(:std :utf8);

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
  ConfigLoader
  Static::Simple

  Authentication
  Authorization::Roles
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name     => 'MyApp',
    encoding => 'UTF-8',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header

    'Model::DB' => {
        connect_info => {
            dsn => 'dbi:SQLite:dbname=:memory:',
            AutoCommit => 1,
            quote_char => '"',
            name_sep => '.',
        }
    },
    'Plugin::Authentication' => {
        'default_realm' => 'default',
        'realms'        => {
            default => {
                credential => {
                    class             => 'Password',
                    password_field    => 'password',
                    password_type     => 'self_check',
                },
                store => {
                    class            => 'DBIx::Class',
                    user_model       => 'DB::User',
                    role_relation    => 'roles',
                    role_field       => 'name',
                }
            }
        }
    }
);

# Start the application
__PACKAGE__->setup();



1;
