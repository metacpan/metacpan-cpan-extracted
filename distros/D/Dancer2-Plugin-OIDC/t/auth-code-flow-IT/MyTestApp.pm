package MyTestApp;
use 5.020;
use Dancer2;

BEGIN {
  set log => 'error';
  set plugins => {
    OIDC => {
      authentication_error_path => '/error/401',
      provider => {
        my_provider => {
          id                   => 'my_id',
          issuer               => 'my_issuer',
          secret               => 'my_secret',
          well_known_url       => '/wellknown',
          signin_redirect_path => '/oidc/login/callback',
          scope                => 'openid profile email',
        },
      },
    },
  };
}

use Dancer2::Plugin::OIDC;

# client server routes
get('/' => sub {
      return 'Welcome!';
    });
get('/protected' => sub {
      if (my $identity = oidc->get_valid_identity()) {
        return $identity->{subject} . ' is authenticated';
      }
      else {
        oidc->redirect_to_authorize();
      }
    });
get('/error/:code' => sub {
      warning("OIDC error : " . session('error_message'));
      status(route_parameters->get('code'));
      return 'Authentication Error';
    });

# provider server routes
get('/authorize' => sub {
      my $redirect_uri  = request->param('redirect_uri');
      my $client_id     = request->param('client_id');
      my $state         = request->param('state');
      my $response_type = request->param('response_type');
      if ($response_type eq 'code' && $client_id eq 'my_id') {
        app->logger_engine->info("redirecting to $redirect_uri");
        redirect("$redirect_uri?client_id=$client_id&state=$state&code=abc&iss=my_issuer");
      }
      else {
        redirect("$redirect_uri?error=error");
      }
    });

1;
