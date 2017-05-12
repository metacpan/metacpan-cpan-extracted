package TestApp;

use Moose;
use Catalyst qw/
  Session
  Session::Store::TestMemcached
  Session::State::Cookie
/;

extends 'Catalyst';

__PACKAGE__->config(
  'Controller::Root', { namespace => '' },
);

__PACKAGE__->setup;
__PACKAGE__->meta->make_immutable;

