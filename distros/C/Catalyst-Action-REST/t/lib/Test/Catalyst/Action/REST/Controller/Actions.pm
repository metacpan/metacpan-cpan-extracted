package Test::Catalyst::Action::REST::Controller::Actions;
use Moose;
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller::REST/ }

__PACKAGE__->_action_class('Test::Action::Class');

sub begin {}  # Don't need serialization..

sub test : Local : ActionClass('+Catalyst::Action::REST') {
    my ( $self, $c ) = @_;
    $c->res->header('X-Was-In-TopLevel', 1);
}

sub test_GET : Private {
    my ( $self, $c ) = @_;
    $c->res->body('GET');
}

sub test_POST : Action {
    my ( $self, $c ) = @_;
    $c->res->body('POST');
}

sub test_PUT :ActionClass('+Test::Action::Class::Sub') {
    my ( $self, $c ) = @_;
    $c->res->body('PUT');
}

sub test_DELETE : Local {
    my ( $self, $c ) = @_;
    $c->res->body('DELETE');
}

sub test_OPTIONS : Path('foobar') {
    my ( $self, $c ) = @_;

    $c->res->body('OPTIONS');
}

sub other_test :Local :ActionClass('+Catalyst::Action::REST') {
    my ( $self, $c ) = @_;
    $c->res->header('X-Was-In-TopLevel', 1);
}

sub other_test_GET {
    my ( $self, $c ) = @_;
    $c->res->body('GET');
}

sub other_test_POST {
    my ( $self, $c ) = @_;
    $c->res->body('POST');
}

sub other_test_PUT :ActionClass('+Test::Action::Class::Sub') {
    my ( $self, $c ) = @_;
    $c->res->body('PUT');
}

sub other_test_DELETE {
    my ( $self, $c ) = @_;
    $c->res->body('DELETE');
}

sub other_test_OPTIONS {
    my ( $self, $c ) = @_;

    $c->res->body('OPTIONS');
}

sub yet_other_test : Local : ActionClass('+Catalyst::Action::REST') {}

sub yet_other_test_POST {
  my ( $self, $c ) = @_;
  $c->res->body('POST');
}

sub end : Private {} # Don't need serialization..

1;

