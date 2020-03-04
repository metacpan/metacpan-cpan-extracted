use strict;
use warnings;
use Carp;

use Plack::App::Path::Router::PSGI;
use Path::Router;
use Plack::Builder;
use Plack::Request;
use Plack::Response;

use lib '../lib';
use Captcha::reCAPTCHA::V3;
my $rc = Captcha::reCAPTCHA::V3->new(
    secret  => '__YOUR_SECRET__',
    sitekey => '__YOUR_SITEKEY__',
);

use Text::Xslate::PP;
my $tx = Text::Xslate->new(
    syntax => 'Kolon',
    cache => 0,
    verbose => 1,
);

my $router = Path::Router->new;
$router->add_route( '/' => target => \&root );
$router->add_route( '/verify' => target => \&verify );

# now create the Plack app
my $app = Plack::App::Path::Router::PSGI->new( router => $router );

return builder {
    if ( !$app && ( my $error = $@ || $! ) ) { die $error; }
    $app->to_app();
};

#===============================================================================
sub root {
    my $env = shift;
    my $body = $tx->render( './template.tx', {
        script4head => $rc->script4head(),
        input4form => $rc->input4form(),
    } );
    return _response( $env, $body );
}

sub verify {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my %param = %{ $req->body_parameters };
    my $content = $rc->verify($param{'reCAPTCHA_Token'});

    my $body = $tx->render( './template.tx', {
        script4head => $rc->script4head(),
        input4form => $rc->input4form(),
#        param => \%param,
        response => $content,
    } );
    
    return _response( $env, $body );
}

sub _response {
    my $env = shift;
    my $body = shift;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    $res->content_length( length $body );
    $res->content_type('text/html; charset=utf-8');
    $res->body($body) unless $req->method eq 'HEAD';
    $res->finalize;
}

