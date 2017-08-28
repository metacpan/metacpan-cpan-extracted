package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::TraitFor::Controller::reCAPTCHA';

__PACKAGE__->config->{namespace} = '';

sub default :Path {
    my ( $self, $c ) = @_;

    my $data = $c->req->params;

    $c->config->{recaptcha}{version} = 'v2'
        if ($data->{test}||'') eq 'v2';

    $c->forward('captcha_get');

    my $body =
        '<html><body><p>recaptcha error: '.
        ($c->stash->{recaptcha_ok} || '') . " " .
        ($c->stash->{recaptcha_error} || '') .
        '</p><form name="recaptcha" action="'.
        $c->uri_for('/check') .  '" method="post">'.
        $c->stash->{recaptcha}.
        ' <br/> <input type="submit" value="submit" /> </form>';

    $c->res->body($body);
}

sub check : Local {
    my ($self, $c) = @_;
    if ( $c->forward('captcha_check') ) {
        $c->res->body( 'OK: ' . $c->stash->{recaptcha_ok} );
    }
    else {
        $c->res->body( 'FAIL: ' . $c->stash->{recaptcha_error} );
    }
}

1;
