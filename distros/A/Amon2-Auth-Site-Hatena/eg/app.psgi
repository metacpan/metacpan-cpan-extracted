#!perl

# usage:
# $ HATENA_CONSUMER_KEY=... HATENA_CONSUMER_SECRET=... plackup eg/app.psgi

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '../lib');

use Amon2::Lite;
use Plack::Builder;

sub config {
    +{
        Auth => {
            Hatena => {
                consumer_key    => $ENV{HATENA_CONSUMER_KEY},
                consumer_secret => $ENV{HATENA_CONSUMER_SECRET},
            }
        }
    }
}

get '/' => sub {
    my $c    = shift;
    my $auth = $c->session->get('auth_hatena') || {};
    $c->render('index.tt', { user => $auth->{user} });
};

get '/logout' => sub {
    my ($c) = @_;
    $c->session->expire;
    $c->redirect('/');
};

__PACKAGE__->load_plugin('Web::Auth', {
    module   => 'Hatena',
    on_error => sub {
        my ($c, $error_message) = @_;
        die $error_message;
    },
    on_finished => sub {
        my ($c, $token, $token_secret, $user) = @_;

        $c->session->set(auth_hatena => {
            user         => $user,
            token        => $token,
            token_secret => $token_secret,
        });

        $c->redirect('/');
    },
});

builder {
    enable 'Plack::Middleware::Session';
    __PACKAGE__->to_app;
};

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
  <meta charst="utf-8">
  <title>MyApp</title>
</head>
<body>
  <h1>Amon2::Auth::Site::Hatena</h1>
  [% IF user %]
    <ul>
      <li>name: <img width="18px" src="[% user.profile_image_url %]"> [% user.url_name %]</li>
      <li>nick: [% user.display_name %]</li>
    </ul>
    <p><a href="/logout">Logout</a></p>
  [% ELSE %]
  <a href="/auth/hatena/authenticate">Login</a>
  [% END %]
</body>
</html>
