package TestApp::Controller::Root;
use strict;
use base 'Catalyst::Controller::Mobile::JP';

__PACKAGE__->config->{namespace} = '';

use Encode;

sub param_test :Local {
    my ($self, $c) = @_;
    $c->res->body(
        $self->encoding->name . '/' .
        Encode::encode('ascii', $c->req->param('text'), Encode::FB_XMLCREF) . '/' .
        $c->req->param('text')
    );
}

sub fallback_test :Local {
    my ($self, $c) = @_;
    $c->res->content_type('text/plain');
    $c->res->body("\x{E6D1}\x{F094}\x{E309}");
    # [DoCoMoにしかないiモードマーク][auにしかないEZマーク][Softbankにしかないトイレ]
}

sub htmlspecialchars_test :Local {
    my ($self, $c) = @_;
    $c->res->content_type( $c->req->param('content_type') );
    $c->res->body("\x{ECA2}"); # DoCoMoにないauの顔 (>３<)
}

1;
