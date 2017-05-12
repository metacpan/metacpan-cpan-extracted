#!/usr/bin/env plackup

use 5.010;
use warnings;
use strict;

use Plack::Request;
use Plack::Builder;
use Plack::App::File;
use Authen::U2F qw(u2f_challenge u2f_registration_verify u2f_signature_verify);
use Template;
use JSON;

my $t = Template->new;

# base app. finds a template file, includes the session and any current u2f
# vars in the stash and expands the template
my $base_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  my $path = $req->request_uri;
  my ($file) = $path eq '/' ? ('index') : $path =~ m{^/(\w+)$};
  return $req->new_response(404)->finalize unless $file && -r "$file.html.tt2";

  my $template = do { local (@ARGV, $/) = ("$file.html.tt2"); <> };
  $t->process(\$template, {
    %$session,
    u2f => $env->{u2f} // {},
  }, \my $output) || die $t->error;

  my $res = $req->new_response(200);
  $res->headers([ 'Content-type' => 'text/html' ]);
  $res->body($output);
  return $res->finalize;
};

# signup. on GET, just goes through to the base app to display the signup page.
# on POST, inserts the passed username into the session, which we use as our "I
# am logged in indicator
my $signup_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  return $base_app->($env) unless $req->method eq 'POST';

  my $params = $req->parameters;
  $session->{$_} = $params->{$_} for keys %$params;
  my $res = $req->new_response;
  $res->redirect('/', 302);
  return $res->finalize;
};

# logout handler. deletes the username in the session, and then returns to the
# root
my $logout_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  delete $session->{username};

  my $res = $req->new_response;
  $res->redirect('/', 302);
  return $res->finalize;
};

# register screen. prepares a registration challenge and then goes to the base
# handler, which will build the page from the register template, which has some
# javascript in it to interact with the U2F device
my $register_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  my $app_id = 'https://'.$req->uri->host;

  $session->{challenge} = u2f_challenge;

  my $register_request = {
    appId => $app_id,
    registerRequest => {
      version   => 'U2F_V2',
      challenge => $session->{challenge},
    },
    registeredKeys => [ map {
      +{ version => 'U2F_V2', keyHandle => $_ }
    } keys %{$session->{registered_keys}} ],
  };

  $env->{u2f}{register_request} = encode_json($register_request);

  return $base_app->($env);
};

# save registration. recieves the signed registration challenge and verifies
# it. if it's all good, it gets saved in the session (in a real app, it would
# get saved in the user's persistent data)
my $save_registration_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  my $app_id = 'https://'.$req->uri->host;

  my ($handle, $key) = u2f_registration_verify(
    challenge         => $session->{challenge},
    app_id            => $app_id,
    origin            => $app_id,
    registration_data => $req->parameters->{registrationData},
    client_data       => $req->parameters->{clientData},
  );

  $session->{registered_keys}{$handle} = $key;

  my $res = $req->new_response;
  $res->redirect('/', 302);
  return $res->finalize;
};

# login. like signup, stores the username in the session to indicate "I am
# logged in". then redirects to a second handler to do the U2F setup
my $login_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  return $base_app->($env) unless $req->method eq 'POST';

  my $params = $req->parameters;
  $session->{$_} = $params->{$_} for keys %$params;
  my $res = $req->new_response;
  $res->redirect('/login_u2f', 302);
  return $res->finalize;
};

# login stage 2, prepare a signing (auth) challenge and then go the the base
# handler to create the page from login_u2f template, which has some javascript
# in it to interacte with the U2F device
my $login_u2f_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  my $app_id = 'https://'.$req->uri->host;

  $session->{challenge} = u2f_challenge;

  my $sign_request = {
    appId => $app_id,
    challenge => $session->{challenge},
    registeredKeys => [ map {
      +{ version => 'U2F_V2', keyHandle => $_ }
    } keys %{$session->{registered_keys}} ],
  };

  $env->{u2f}{sign_request} = encode_json($sign_request);

  return $base_app->($env);
};

# finish u2f. recieves the signed auth challenge and verifies it. if it checks
# out, the user is now logged in
my $finish_u2f_app = sub {
  my ($env) = @_;
  my $req = Plack::Request->new($env);
  my $session = $req->session;

  my $app_id = 'https://'.$req->uri->host;

  my $key_handle = $req->parameters->{keyHandle};

  my ($handle, $key) = u2f_signature_verify(
    challenge         => $session->{challenge},
    app_id            => $app_id,
    origin            => $app_id,
    key_handle        => $key_handle,
    key               => $session->{registered_keys}{$key_handle},
    signature_data    => $req->parameters->{signatureData},
    client_data       => $req->parameters->{clientData},
  );

  my $res = $req->new_response;
  $res->redirect('/', 302);
  return $res->finalize;
};

builder {
  enable 'Session';

  mount '/u2f-api.js' => Plack::App::File->new(file => 'u2f-api.js')->to_app;

  mount '/signup' => $signup_app;

  mount '/logout' => $logout_app;

  mount '/register'          => $register_app;
  mount '/save_registration' => $save_registration_app;

  mount '/login'      => $login_app;
  mount '/login_u2f'  => $login_u2f_app;
  mount '/finish_u2f' => $finish_u2f_app;

  mount '/' => $base_app;
}
