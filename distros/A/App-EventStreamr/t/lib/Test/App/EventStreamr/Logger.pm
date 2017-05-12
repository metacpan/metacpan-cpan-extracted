package Test::App::EventStreamr::Logger;
use Moo;
use namespace::clean;

has config => ( is => 'rw' );

with('App::EventStreamr::Roles::Logger');

1;
