package RemoteTestApp1::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config(namespace => '');

sub default : Local {
    my ( $self, $c ) = @_;
    if ($c->authenticate()) {
        $c->res->body('User:' . $c->user->{username});
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

