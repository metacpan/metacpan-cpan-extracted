package Test::Action::Class::Sub;
use Moose;

extends 'Test::Action::Class';

before execute => sub {
   my ($self, $controller, $c, @args) = @_;
   $c->response->header( 'Using-Sub-Action' => 'MOO' );
};

no Moose;

1;
