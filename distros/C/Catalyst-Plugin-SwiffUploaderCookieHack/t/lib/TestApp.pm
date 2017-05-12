package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw(
  SwiffUploaderCookieHack

  Session
  Session::Store::File
  Session::State::Cookie
);

extends 'Catalyst';

__PACKAGE__->setup;

1;
