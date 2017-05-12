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




note('this try to create and user. it not really test each class of CatalystX::Eta, but only works if it CatalystX::Eta is working!');

api_auth_as user_id => 1;

db_transaction {

    rest_post '/users',
      name  => 'criar user',
      list  => 1,
      stash => 'user',
      [
        name     => 'Foo Bar',
        email    => 'foo1@email.com',
        password => 'foobarquux1',
        role     => 'user'
      ];

    stash_test 'user.get', sub {
        my ($me) = @_;

        is( $me->{id},    stash 'user.id',  'get has the same id!' );
        is( $me->{email}, 'foo1@email.com', 'email ok!' );
        is( $me->{type}, 'user', 'type is correct !' );
    };

    stash_test 'user.list', sub {
        my ($me) = @_;

        ok( $me = delete $me->{users}, 'users list exists' );

        is( @$me, 2, '2 users' );

        $me = [ sort { $a->{id} <=> $b->{id} } @$me ];

        is( $me->[1]{email}, 'foo1@email.com', 'listing ok' );
    };

    rest_put stash 'user.url',
      name => 'update user fail',
      is_fail => 1,
      code => 403,
      [
        name     => 'AAAAAAAAA',
        email    => 'foo2@email.com',
        password => 'foobarquux1',
        role     => 'user'
      ];

    api_auth_as user_id => stash 'user.id';
    rest_put stash 'user.url',
      name => 'update user ',
      [
        name     => 'AAAAAAAAA',
        email    => 'foo2@email.com',
        password => 'foobarquux1',
        role     => 'user'
      ];

    api_auth_as user_id => 1;

    rest_reload 'user';

    stash_test 'user.get', sub {
        my ($me) = @_;

        is( $me->{email}, 'foo2@email.com', 'email updated!' );
    };

    api_auth_as user_id => stash 'user.id';
    rest_delete stash 'user.url';

    api_auth_as user_id => 1;

    rest_reload 'user', code => 404;

    # ao inves de
    # my $list = rest_get '/users';
    # use DDP; p $list;

    # utilizar

    rest_reload_list 'user';

    stash_test 'user.list', sub {
        my ($me) = @_;

        ok( $me = delete $me->{users}, 'users list exists' );

        is( @$me, 1, '1 users' );

        is( $me->[0]{email}, 'superadmin@email.com', 'listing ok' );
    };


    rest_post '/users',
      name  => 'add user',
      stash => 'user1',
      [
        name     => 'Foo Bar',
        email    => 'foox@email.com',
        password => 'foobarquux1',
        role     => 'user'
      ];

    rest_post '/users',
      name    => 'try add user with same email',
      stash   => 'user2',
      is_fail => 1,
      [
        name     => 'Foo Bar',
        email    => 'foox@email.com',
        password => 'foobarquux1',
        role     => 'user'
      ];

    stash_test 'user2', sub {
        my ($me) = @_;
        check_invalid_error 'user2', 'email', 'invalid';
    };


};




done_testing;
