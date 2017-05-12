package MyApp1::Controller::Root;

use Moose;
use CatalystX::Routes;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config()->{namespace} = q{};

our %REQ;

get q{} => args 0 => sub { $REQ{root}++ };

get q{foo.txt} => args 0 => sub { $REQ{'foo.txt'}++ };

1;
