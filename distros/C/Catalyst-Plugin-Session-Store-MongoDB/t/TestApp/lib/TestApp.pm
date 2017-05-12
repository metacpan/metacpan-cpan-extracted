package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
  ConfigLoader
  Static::Simple
  Session
  Session::State::Cookie
  Session::Store::MongoDB
/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

__PACKAGE__->config(
  name => 'TestApp',
  # Disable deprecated behavior needed by old applications
  disable_component_resolution_regex_fallback => 1,

  'Plugin::Session' => {
    client_options => {
      host => $ENV{MONGODB_HOST},
      port => $ENV{MONGODB_PORT},
    },
    dbname => $ENV{TEST_DB},
    collectionname => $ENV{TEST_COLLECTION},
  },
);

__PACKAGE__->setup();

1;
