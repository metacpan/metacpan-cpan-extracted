package Test::App::EventStreamr::ProcessControl;
use Method::Signatures;
use Moo;
use namespace::clean;

has 'cmd' => ( is => 'ro', default  => sub { "ping 127.0.0.1" });
has 'cmd_regex'   => ( is => 'ro' );
has 'id' => ( is => 'ro', default  => sub { "ping" });

with('App::EventStreamr::Roles::ProcessControl');

1;
