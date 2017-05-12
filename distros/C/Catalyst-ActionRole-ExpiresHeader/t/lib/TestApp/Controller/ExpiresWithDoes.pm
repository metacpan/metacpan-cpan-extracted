package TestApp::Controller::ExpiresWithDoes;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

use HTTP::Date qw( time2str );

sub expires_in_one_day  : Local Does('ExpiresHeader') Expires('+1d') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '+1d' ) );
}

sub expires_fixed  : Local Does('ExpiresHeader') Expires('Wed, 26 May 2010 12:37:59 GMT') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', 'Wed, 26 May 2010 12:37:59 GMT' ) );
}

sub already_expired  : Local Does('ExpiresHeader') Expires('-1d') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '-1d' ) );
}

sub expires_already_set  : Local Does('ExpiresHeader') Expires('+1d') {
    my ($self, $c) = @_;
    my $expires_in_one_hour = time2str( time + 3600 );
    $c->res->header( Expires => $expires_in_one_hour );
    $c->res->body( join(":", $c->action->name, 'Expires', '+1h') );
}

sub no_expires  : Local {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name) );
}

sub empty_expires  : Local Does('ExpiresHeader') Expires {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '' ) );
}

sub zero_expires  : Local Does('ExpiresHeader') Expires('0') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '0' ) );
}

sub expires_now  : Local Does('ExpiresHeader') Expires('now') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', 'now' ) );
}

sub expires_in_epoch  : Local Does('ExpiresHeader') Expires('1274879357') {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name, 'Expires', '1274879357' ) );
}



1;
