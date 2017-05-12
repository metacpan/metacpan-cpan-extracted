package ExampleView;
use Moose::Role;
use namespace::autoclean;

around process => sub {
    my ($orig, $self, $c) = @_;
    $c->res->body("Processed by view " . blessed($self));
};

1;

