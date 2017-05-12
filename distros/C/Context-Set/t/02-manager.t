#!perl -T
use strict;
use warnings;
use Test::More tests => 42;
use Test::Fatal qw/dies_ok lives_ok/;
use Context::Set::Manager;


my $cm = Context::Set::Manager->new();
my $universe = $cm->universe();
cmp_ok( $universe->name() , 'eq' , 'UNIVERSE'  , "Ok good universe name");

cmp_ok( $universe->fullname() , 'eq' , 'UNIVERSE' , "Ok good fullname for universe");

$universe->set_property('pi' , 3.14159 );
$universe->set_property('null');

ok( $universe->has_property('pi') , "Ok universe has property pi");
ok( $universe->has_property('null') , "Ok universe has property null");
ok( ! defined $universe->get_property('null') , "The value of property null is undef");
cmp_ok( $universe->get_property('pi') , '==' , 3.14159, "Ok can get pi");

ok( ! $universe->has_property('somethingelse') , "somethingelse is not there");
dies_ok { $universe->get_property('somethingelse') } "Fails to get a property that is not there";

my $users_context = $cm->restrict('users');

cmp_ok( $users_context->fullname(), "eq" , "UNIVERSE/users" , "Ok good fullname for users");
cmp_ok( $users_context->name() , 'eq' , 'users' , "Ok name is good");
cmp_ok( $users_context->restricted()->name() , 'eq' , $universe->name() , "Ok restricted right context");

$users_context->set_property('color' , 'blue');
ok( $users_context->has_property('pi') , "Ok can find pi in the restriction too");
ok( $users_context->has_property('color') , "Ok users have property color");
cmp_ok( $users_context->get_property('color') , "eq" , 'blue' , "Ok can get color from users");

## Test that we cannot restrict a non existing context.
ok( $cm->find('UNIVERSE') , "Ok can find the universe");
ok( $cm->find('UNIVERSE/users') , "Ok can find the users in the universe");
ok( $cm->find('users') , "Ok can find a context with a local name 'users'");
ok(! $cm->find('boudinblanc') , "Ok cannot find the boudin blanc context");


dies_ok { $cm->restrict('boudinblanc', '1') }  "Ok cannot restrict a non managed context";

## Test context of user 1
my $user1_ctx = $cm->restrict('users', '1');
cmp_ok( $user1_ctx->name() , 'eq' , '1' , "Ok good name");
ok( $user1_ctx->has_property('pi') , "Ok user 1 knows pi");
ok( $user1_ctx->has_property('color') , "Ok user 1 knows color");
cmp_ok( $user1_ctx->get_property('pi') , '==' , 3.14159 , "Ok can get pi from user 1");
cmp_ok( $user1_ctx->get_property('color') , "eq" , 'blue' , "Ok can get color from user 1");


## Test user 2.
my $user2_ctx = $cm->restrict('users', '2');
cmp_ok( $user2_ctx->fullname() , 'eq' , 'UNIVERSE/users/2' , "Ok good fullname");
cmp_ok( $user2_ctx->get_property('color') , 'eq' , 'blue' , "Got color blue");
$user2_ctx->set_property('color' , 'black');
cmp_ok( $user2_ctx->get_property('color') , 'eq' , 'black' , "Got color black only in user 2");


my $lists = $cm->restrict('lists');
my $list1 = $cm->restrict($lists, '1');

my $u1l1 = $cm->unite($user1_ctx , $list1);

diag("Got union: ".$u1l1->fullname());

## Setting flavour in different contexts:
$universe->set_property('flavour', 'vanilla');
$universe->set_property('smell', 'rose');
$user1_ctx->set_property('flavour' , 'banana');
$list1->set_property('flavour', 'blueberry');
$u1l1->set_property('flavour' , 'apple');
$list1->set_property('smell' , 'caramel');

## Testing we got the right values in different contexts
my $list2 = $cm->restrict('lists', '2');
my $another_list = $cm->restrict('lists' , 2);
cmp_ok( $list2.'' , 'eq' , $another_list.'', "Got two identical objects for two different restrictions operations");

my $u1l2 = $cm->unite($user1_ctx , $list2->name());

cmp_ok( $u1l2->get_property('flavour') , 'eq' , 'banana' , "Got banana for user 1 any list");

my $u2l2 = $user2_ctx->unite($list2);
cmp_ok( $u2l2->get_property('flavour') , 'eq' , 'vanilla' , 'Got vanilla for any user , any list');

## here we'll use the flavour of list1 (blueberry), because the flavour on the user
## is in the super context only.
## The order is important.
my $u2l1 = $cm->unite( $list1, $user2_ctx );
cmp_ok( $u2l1->get_property('flavour') , 'eq' , 'blueberry' , "Got blueberry for any user , list 1");
is( $u2l1->get_property('smell') , 'caramel' , "list 1 smells of caramel for all users");
is( $u2l1->lookup('smell')->delete_property('smell') , 'caramel' , "Can delete caramel from list1");
is( $u2l1->get_property('smell') , 'rose' , "list1 now smells of rose, like the universe");

cmp_ok( $u1l1->get_property('flavour'), 'eq' , 'apple', "Got apple for user 1, list 1");

my $u23 = $cm->restrict('users', 23);
my $u23l1 = $cm->unite( $u23 , $list1);
cmp_ok( $u23l1->get_property('flavour') , 'eq' , 'blueberry', "Got blueberry for any user list 1");

my $list45 = $cm->restrict('lists', 45);
my $u23l45 = $cm->unite($u23 , $list45);
cmp_ok( $u23l45->get_property('flavour'), 'eq' , 'vanilla' , "Got vanilla for any user, any list");

{
  ## Restrict lists and check that it's managed.
  my $felix = $lists->restrict('felix');
  ok( $cm->find('felix') , "Ok found felix in the manager, although its been created outside");

  ## Unite felix with something else and check the union is managed.
  my $union = $felix->unite($u23);
  ok( $cm->find($union->fullname()) , "Ok can find the fullname of the union in the manager");

  my $cm2 = Context::Set::Manager->new();
  my $aliens = $cm2->restrict('aliens');
  ok( !$cm->find('aliens') , "No alien in main manager");
  $union->unite($aliens);
  ok( $cm->find('aliens') , "Aliens have been imported in the original manager");
  ok( $cm->find($union->fullname()) , "New union can be found in the manager");
}


done_testing();
