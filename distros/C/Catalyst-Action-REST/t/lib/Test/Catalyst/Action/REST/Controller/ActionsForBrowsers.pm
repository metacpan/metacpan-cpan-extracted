package Test::Catalyst::Action::REST::Controller::ActionsForBrowsers;
use Moose;
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller::REST/ }

sub begin {}  # Don't need serialization..

sub for_browsers : Local : ActionClass('REST::ForBrowsers') {
    my ( $self, $c ) = @_;
    $c->res->header('X-Was-In-TopLevel', 1);
}

sub for_browsers_GET : Private {
    my ( $self, $c ) = @_;
    $c->res->body('GET');
}

sub for_browsers_GET_html : Private {
    my ( $self, $c ) = @_;
    $c->res->body('GET_html');
}

sub for_browsers_POST : Private {
    my ( $self, $c ) = @_;
    $c->res->body('POST');
}

sub end : Private {} # Don't need serialization..

1;

