package TestApp::Controller::ExpiresWithActionRoles;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

use HTTP::Date qw( time2str );

__PACKAGE__->config(
    action_roles => [qw( ExpiresHeader )],
);


sub expires_in_one_day  : Local Expires('+1d') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '+1d' ) );
}

sub expires_fixed  : Local Expires('Wed, 26 May 2010 12:37:59 GMT') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', 'Wed, 26 May 2010 12:37:59 GMT' ) );
}

sub already_expired  : Local Expires('-1d') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '-1d' ) );
}

sub expires_already_set  : Local Expires('+1d') {
    my ($self, $c) = @_;
    my $expires_in_one_hour = time2str( time + 3600 );
    $c->res->header( Expires => $expires_in_one_hour );
    $c->res->body( join(":", $c->action->name, 'Expires', '+1h') );
}

sub no_expires  : Local {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name) );
}

sub empty_expires  : Local Expires {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '' ) );
}

sub zero_expires  : Local Expires('0') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '0' ) );
}

sub expires_now  : Local Expires('now') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', 'now' ) );
}

sub expires_in_epoch  : Local Does('ExpiresHeader') Expires('1274879357') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '1274879357' ) );
}

1;
