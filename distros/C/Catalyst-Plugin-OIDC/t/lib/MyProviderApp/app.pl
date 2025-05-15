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
    userinfo_endpoint      => '/userinfo',
    jwks_uri               => '/jwks',
  );
  $c->render(json => {map { $_ => $url{$_} } keys %url});
});
# get '/authorize' in MyCatalystApp/Controller/Root.pm (ugly but necessary)
post('/token' => sub {
       my $c = shift;
       my $grant_type    = $c->param('grant_type');
       my $client_id     = $c->param('client_id');
       my $client_secret = $c->param('client_secret');
       my $code          = $c->param('code');
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

get('/userinfo' => sub {
      my $c = shift;

      my $authorization = $c->req->headers->authorization;

      if ($authorization eq 'Bearer Doe') {
        $c->render(json => {
          sub       => 'DOEJ',
          firstName => 'John',
          lastName  => 'Doe',
          roles     => [qw/app.role1 app.role2/],
        });
      }
      elsif ($authorization eq 'Bearer Smith') {
        $c->render(json => {
          sub       => 'SMITHL',
          firstName => 'Liam',
          lastName  => 'Smith',
          roles     => [qw/app.role3/],
        });
      }
      else {
        $c->render(json => {error             => 'SearchError',
                            error_description => 'User not found'},
                   status => 404);
      }
    });

app->start;

return app;
