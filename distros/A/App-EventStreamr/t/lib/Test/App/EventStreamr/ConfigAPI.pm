package Test::App::EventStreamr::ConfigAPI;
use Moo;
use namespace::clean;

extends 'App::EventStreamr::Config';

has 'config_path'   => ( is => 'ro', default  => sub { "/tmp/controller" });
has 'macaddress'    => ( is => 'ro', default  => sub { "00:00:00:00:00:00" });

with('App::EventStreamr::Roles::ConfigAPI');

1;
