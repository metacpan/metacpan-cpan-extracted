#!perl -T
use strict;
use warnings;
use Test::More tests => 30;
use Test::Fatal qw/dies_ok lives_ok/;
use Context::Set;


my $universe = Context::Set->new();
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

my $users_context = $universe->restrict('users');

cmp_ok( $users_context->fullname(), "eq" , "UNIVERSE/users" , "Ok good fullname for users");
cmp_ok( $users_context->name() , 'eq' , 'users' , "Ok name is good");
cmp_ok( $users_context->restricted()->name() , 'eq' , $universe->name() , "Ok restricted right context");

$users_context->set_property('color' , 'blue');
ok( $users_context->has_property('pi') , "Ok can find pi in the restriction too");
ok( $users_context->has_property('color') , "Ok users have property color");
cmp_ok( $users_context->get_property('color') , "eq" , 'blue' , "Ok can get color from users");

## Test context of user 1
my $user1_ctx = $users_context->restrict('1');
cmp_ok( $user1_ctx->name() , 'eq' , '1' , "Ok good name");
ok( $user1_ctx->has_property('pi') , "Ok user 1 knows pi");
ok( $user1_ctx->has_property('color') , "Ok user 1 knows color");
cmp_ok( $user1_ctx->get_property('pi') , '==' , 3.14159 , "Ok can get pi from user 1");
cmp_ok( $user1_ctx->get_property('color') , "eq" , 'blue' , "Ok can get color from user 1");


## Test user 2.
my $user2_ctx = $users_context->restrict('2');
cmp_ok( $user2_ctx->fullname() , 'eq' , 'UNIVERSE/users/2' , "Ok good fullname");
cmp_ok( $user2_ctx->get_property('color') , 'eq' , 'blue' , "Got color blue");
$user2_ctx->set_property('color' , 'black');
cmp_ok( $user2_ctx->get_property('color') , 'eq' , 'black' , "Got color black only in user 2");


my $lists = $universe->restrict('lists');
my $list1 = $lists->restrict('1');

my $u1l1 = $user1_ctx->unite($list1);

diag("Got union: ".$u1l1->fullname());

## Setting flavour in different contexts:
$universe->set_property('flavour', 'vanilla');
$user1_ctx->set_property('flavour' , 'banana');
$list1->set_property('flavour', 'blueberry');
$u1l1->set_property('flavour' , 'apple');

## Testing we got the right values in different contexts
my $list2 = $lists->restrict('2');
my $u1l2 = $user1_ctx->unite($list2);

cmp_ok( $u1l2->get_property('flavour') , 'eq' , 'banana' , "Got banana for user 1 any list");

my $u2l2 = $user2_ctx->unite($list2);
cmp_ok( $u2l2->get_property('flavour') , 'eq' , 'vanilla' , 'Got vanilla for any user , any list');

## here we'll use the flavour of list1 (blueberry), because the flavour on the user
## is in the super context only.
my $u2l1 = $user2_ctx->unite($list1);
cmp_ok( $u2l1->get_property('flavour') , 'eq' , 'blueberry' , "Got blueberry for any user , list 1");

cmp_ok( $u1l1->get_property('flavour'), 'eq' , 'apple', "Got apple for user 1, list 1");

my $u23 = $users_context->restrict(23);
my $u23l1 = $u23->unite($list1);
cmp_ok( $u23l1->get_property('flavour') , 'eq' , 'blueberry', "Got blueberry for any user list 1");

my $list45 = $lists->restrict(45);
my $u23l45 = $u23->unite($list45);
cmp_ok( $u23l45->get_property('flavour'), 'eq' , 'vanilla' , "Got vanilla for any user, any list");

is( $list1->delete_property('flavour') , 'blueberry' , "Ok can delete flavour from list 1");
cmp_ok( $u23l1->get_property('flavour') , 'eq' , 'vanilla', "Got vanilla ( as opposed to blueberry )");


done_testing();
