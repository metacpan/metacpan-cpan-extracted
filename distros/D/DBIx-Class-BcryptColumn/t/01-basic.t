#!/usr/bin/env perl

use lib 't/lib';
use Test::More 0.86;
use Test::DBIx::Class 
  -schema_class => 'Schema',
  qw(:resultsets);

is_deeply User->result_class->_bcrypt_columns_info, +{ password=>{cost=>12} };
is_deeply [User->result_class->bcrypt_columns], ['password'];

ok my $user = User->create({name=>'Foo', password=>'abc123'});
ok $user->check_password('abc123'), 'password check passes';
ok my $id = $user->id;
ok $hashed_pwd = $user->password;

ok $user->update({name=>'John'});
ok $user->check_password('abc123');
is $user->name, 'John';
is $user->password, $hashed_pwd; # didn't change / reinsert

{
  ok my $user = User->find({id=>$id});
  ok $user->check_password('abc123');
  is $user->name, 'John';
  is $user->password, $hashed_pwd; # didn't change / reinsert

  $user->password('123abc');
  $user->update;

  {
    ok my $user = User->find({id=>$id});
    ok $user->check_password('123abc');
  }
}

ok my $new = User->new_result(+{name=>'Joo'});
$new->password('xyz098');
$new->insert;
ok $new->in_storage;
ok $new->check_password('xyz098');

done_testing;
