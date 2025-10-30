#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Mojolicious::Lite;

# provider server routes
get('/wellknown' => sub {
  my $c = shift;
  my %url = (
    authorization_endpoint => '/authorize',
    end_session_endpoint   => '/logout',
    token_endpoint         => '/token',
    jwks_uri               => '/jwks',
  );
  $c->render(json => {map { $_ => $url{$_} } keys %url});
});
# get '/authorize' in MyCatalystApp/Controller/Root.pm (ugly but necessary)
post('/token' => sub {
       my $c = shift;
       my ($client_id, $client_secret) = split(':', $c->req->url->to_abs->userinfo);
       my $grant_type = $c->param('grant_type');
       my $code       = $c->param('code');
       if ($grant_type eq 'authorization_code'
           && $client_id eq 'my_id' && $client_secret eq 'my_secret'
           && $code eq 'abc') {
         $c->render(json => {id_token      => 'my_id_token',
                             access_token  => 'my_access_token',
                             refresh_token => 'my_refresh_token',
                             scope         => 'openid profile email',
                             token_type    => 'Bearer',
                             expires_in    => 3599});
       }
       else {
         $c->render(json => {error             => 'error',
                             error_description => 'error_description'},
                    status => 401);
       }
     });

app->start;

return app;
