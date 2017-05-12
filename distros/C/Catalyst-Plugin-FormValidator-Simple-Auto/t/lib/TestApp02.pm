package TestApp02;

use Catalyst qw/
    FormValidator::Simple
    FormValidator::Simple::Auto
    /;

__PACKAGE__->config(
    name      => 'TestApp',
    validator => {
        profiles => {
            action1        => {param1 => ['NOT_BLANK', 'ASCII'],},
            action2_submit => {param1 => ['NOT_BLANK', 'ASCII'],},
        },
    },
);
__PACKAGE__->setup;

sub action1 : Global {
    my ($self, $c) = @_;

    if ($c->form->has_error) {
        $c->res->body($c->form->error('param1'));
    } else {
        $c->res->body('no errors');
    }
}

sub action2 : Global {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        $c->forward('action2_submit');
    } else {
        $c->res->body('no $c->form executed');
    }
}

sub action2_submit : Private {
    my ($self, $c) = @_;

    if ($c->form->has_error) {
        $c->res->body($c->form->error('param1'));
    } else {
        $c->res->body('no errors');
    }
}

1;

