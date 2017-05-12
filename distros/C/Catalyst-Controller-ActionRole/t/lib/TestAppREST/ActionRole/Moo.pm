package TestAppREST::ActionRole::Moo;

use Moose::Role;

after execute => sub {
    my ($self, $controller, $c) = @_;
    $c->response->header('X-Affe' => 'Tiger');
    $c->response->body(__PACKAGE__);
};

1;
