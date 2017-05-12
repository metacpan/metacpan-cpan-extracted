package RemoteTestApp2::Controller::Root;
use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub default : Local {
    my ( $self, $c ) = @_;
    if ($c->authenticate()) {
        $c->res->body(
              'my_user_name:'
              . $c->user->{my_user_name}
        );
    }
    else {
        $c->res->body('FAIL');
        $c->res->status(403);
    }
}

sub public : Local {
    my ( $self, $c ) = @_;
    $c->res->body('OK');
}

1;

