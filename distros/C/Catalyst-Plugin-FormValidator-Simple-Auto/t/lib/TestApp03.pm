package TestApp03;

use Catalyst qw/
    FormValidator::Simple
    FormValidator::Simple::Auto
    /;

__PACKAGE__->config(
    name => 'TestApp',
    validator =>
        {profiles => {action1 => {param1 => ['NOT_BLANK', 'ASCII'],},},},
);
__PACKAGE__->setup;

sub action1 : Global {
    my ($self, $c) = @_;

    $c->res->body($c->validator_profile);
}

sub action2 : Global {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        $c->forward('action1');
    }
}

sub action3 : Global {
    my ($self, $c) = @_;
    $c->forward('action1');
    $c->res->body($c->validator_profile);
}

1;

