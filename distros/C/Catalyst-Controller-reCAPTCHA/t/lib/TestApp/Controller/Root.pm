package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller::reCAPTCHA';

sub index :Private {
    my ($self, $c) = @_;
    $c->forward('captcha_get');
    my $body ='<html>  <body> <p> recaptcha error: '. $c->stash->{recaptcha_ok} . " " . $c->stash->{recaptcha_error} . '</p><form name="recaptcha" action="'. $c->uri_for('/check') . '" method="post">'. $c->stash->{recaptcha}.' <br/> <input type="submit" value="submit" /> </form>';
    $c->res->body($body);
}

sub check : Local {
    my ($self, $c) = @_;
    $c->forward('captcha_check');
    $c->detach('index');
}

1;
