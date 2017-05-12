package TestApp05;

use Catalyst qw/
    FormValidator::Simple
    FormValidator::Simple::Auto
    /;

__PACKAGE__->config(
    name      => 'TestApp',
    validator => {
        profiles => {
            action1 => {
                param1 => [
                    {rule => 'NOT_BLANK', message => 'NOT_BLANK!!!'},
                    {rule => 'ASCII',     message => 'ASCII!!!'},
                ],
            },
        },
    },
);
__PACKAGE__->setup;

sub action1 : Global {
    my ($self, $c) = @_;

    if ($c->form->has_error) {
        if (($c->req->params->{as} || '') eq 'hash') {
            $c->res->body($c->form_messages->{param1}->[0]);
        } else {
            $c->res->body($c->form_messages('param1')->[0]);
        }
    } else {
        $c->res->body('no errors');
    }
}

1;

