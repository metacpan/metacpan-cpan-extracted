package Test::App::EventStreamr::Process;
use Moo;
use namespace::clean;

extends 'App::EventStreamr::Process';

has 'cmd' => ( is => 'ro', default  => sub { "ping 127.0.0.1" });
has 'id' => ( is => 'ro', default  => sub { "ping" });

1;
