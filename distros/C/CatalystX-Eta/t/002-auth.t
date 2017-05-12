use utf8;
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";

use Test::More;

use MyApp::Test::Further;

my $model = MyApp->model('DB');
ok($model, 'model loaded');
eval {
    $model->schema->deploy_with_users
};
is($@, '', 'database deployed success');


db_transaction {

    my $res = rest_get '/users', code => 403, is_fail => 1;
    is($res->{error}, 'access denied','access denied');

    rest_post '/login',
      name  => 'test login',
      is_fail => 1,
      stash => 'login',
      [
        'email'    => 'superadmin@email.com',
        'password' => '1234'
      ];

    stash_test 'login', sub {
        my ($me) = @_;

        is($me->{error}, "Login invalid(2)", 'Login invalid');
    };

    rest_post '/login',
      name  => 'teste o login',
      code  => 200,
      stash => 'login',
      [
        'email'    => 'superadmin@email.com',
        'password' => '123'
      ];

    stash_test 'login', sub {
        my ($me) = @_;

        ok($me->{api_key}, 'has api_key');
        is($me->{email}, 'superadmin@email.com', 'email ok');

        is_deeply($me->{roles}, ['superadmin'], 'roles looks good');

        my $users = rest_get '/users', 200, params => [api_key => $me->{api_key}];

        is (@{$users->{users}}, 1, 'have 1 users');

    };

};

done_testing;


