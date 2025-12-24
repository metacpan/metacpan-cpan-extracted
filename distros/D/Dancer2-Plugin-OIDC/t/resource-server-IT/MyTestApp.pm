package MyTestApp;
use 5.020;
use Dancer2;
use Try::Tiny;

BEGIN {
  set log => 'error';
  set plugins => {
    OIDC => {
      provider => {
        my_provider => {
          id          => 'my_id',
          issuer      => 'my_issuer',
          secret      => 'my_secret',
          role_prefix => 'app.',
          jwks_url    => '/jwks',
          claim_mapping => {
            login     => 'sub',
            lastname  => 'lastName',
            firstname => 'firstName',
            email     => 'email',
            roles     => 'roles',
          },
        },
      },
    },
  };
}

use Dancer2::Plugin::OIDC;

# resource server routes
get('/my-resource' => sub {
      my $user = try {
        my $access_token = oidc->verify_token();
        return oidc->build_user_from_claims($access_token->claims);
      }
      catch {
        warning("Token/User validation : $_");
        return;
      } or do {
        status(401);
        return encode_json({error => 'Unauthorized'});
      };

      unless ($user->has_role('role2')) {
        warning("Insufficient roles");
        status(403);
        return encode_json({error => 'Forbidden'});
      }

      return encode_json({user_login => $user->login});
    });

1;
