#!perl -T
use strict;
use warnings;
use Test::More tests => 68;
use Test::Fatal qw/dies_ok lives_ok/;
use Context::Set::Manager;
use Context::Set::Storage::DBIC;
use Context::Set::Storage::Split;

use DBI;
use DBD::SQLite;

use Log::Log4perl qw/:easy/;
Log::Log4perl->easy_init($DEBUG);

package My::Schema;
## This is a schema that will be build dynamically.
use base qw/DBIx::Class::Schema::Loader/;
__PACKAGE__->naming('current');
1;
package main;

my $dbh = DBI->connect("dbi:SQLite::memory:" , "", "");
$dbh->{AutoCommit} = 1;
$dbh->do(q|CREATE TABLE contextvalue(id INTEGER PRIMARY KEY AUTOINCREMENT,
context_name VARCHAR(512) NOT NULL,
is_array BOOLEAN NOT NULL,
key VARCHAR(512) NOT NULL,
value VARCHAR(512));|);


## For the split storage
$dbh->do(q|
CREATE TABLE aa(id INTEGER PRIMARY KEY AUTOINCREMENT,
context_name VARCHAR(512) NOT NULL,
is_array BOOLEAN NOT NULL,
key VARCHAR(512) NOT NULL,
value VARCHAR(512));|);

$dbh->do(q|
CREATE TABLE bb(id INTEGER PRIMARY KEY AUTOINCREMENT,
context_name VARCHAR(512) NOT NULL,
is_array BOOLEAN NOT NULL,
key VARCHAR(512) NOT NULL,
value VARCHAR(512));|);

## Build a schema dynamically.
ok( my $schema = My::Schema->connect(sub{ return $dbh ;} , { unsafe => 1 } ), "Ok built schema with dbh");
cmp_ok( scalar($schema->sources) , 'eq' , 3 , "3 sources in schema");

ok( my $rs = $schema->resultset('Contextvalue') , "Ok got resultset");

## And build a Context storage.
my $storage_dbic = Context::Set::Storage::DBIC->new({ resultset => $rs });

## We also need a split storage
my $users_store = Context::Set::Storage::DBIC->new({ resultset => scalar($schema->resultset('Aa')) });
my $general_store = Context::Set::Storage::DBIC->new({ resultset => scalar($schema->resultset('Bb')) });

my $split_store = Context::Set::Storage::Split->new({
                                                     rules => [{
                                                                name => 'users_specific',
                                                                test => sub{ shift->is_inside('users'); },
                                                                storage => $users_store
                                                               },
                                                               {
                                                                name => 'lists_specific',
                                                                test => sub{ shift->is_inside('lists'); },
                                                                storage => $general_store
                                                               },
                                                               {
                                                                name => 'default',
                                                                test => sub{ 1; },
                                                                storage => $general_store
                                                               }]
                                                    });

foreach my $storage ( $storage_dbic , $split_store ){
  {
    ## The manager under which stuff are stored
    my $cm = Context::Set::Manager->new({ storage => $storage });
    my $universe = $cm->universe();
    cmp_ok( $universe->name() , 'eq' , 'UNIVERSE'  , "Ok good universe name");
    ok( $universe->storage() , "Ok universe has got a storage");
    cmp_ok( $universe->fullname() , 'eq' , 'UNIVERSE' , "Ok good fullname for universe");
    $universe->set_property('pi' , 3.14159 );
    $universe->set_property('null');
    $universe->set_property('beers' , [ 'stella' ]);

    my $users_context = $cm->restrict('users');
    $users_context->set_property('beers', [ 'duvel' , 'chimay' ]);
    $users_context->set_property('color' , 'blue');

    my $user2_ctx = $cm->restrict('users', '2');
    $user2_ctx->set_property('color' , 'black');
    my $lists = $cm->restrict('lists');
    my $list1 = $cm->restrict($lists, '1');

    my $user1_ctx = $cm->restrict('users', '1');
    my $u1l1 = $cm->unite($user1_ctx , $list1);

    $universe->set_property('flavour', 'vanilla');
    $user1_ctx->set_property('flavour' , 'banana');
    $list1->set_property('flavour', 'blueberry');
    $u1l1->set_property('flavour' , 'apple');
  } ## End of storing things.

  {
    ## Another manager with no value setting.
    my $cm = Context::Set::Manager->new({ storage => $storage, autoreload => 1 });
    my $universe = $cm->universe();
    ok( $universe->has_property('pi') , "Ok universe has property pi");
    ok( $universe->has_property('null') , "Ok universe has property null");
    ok( ! defined $universe->get_property('null') , "The value of property null is undef");
    cmp_ok( $universe->get_property('pi') , '==' , 3.14159, "Ok can get pi");
    is_deeply( $universe->get_property('beers') , [ 'stella' ] , "Ok good beers property on universe");

    ok( ! $universe->has_property('somethingelse') , "somethingelse is not there");
    dies_ok { $universe->get_property('somethingelse') } "Fails to get a property that is not there";

    my $users_context = $cm->restrict('users');
    is_deeply( $users_context->get_property('beers') , [ 'duvel' , 'chimay' ] , "Ok good table of properties back");
    ## Fiddle with the property hash of this context.
    ## To check the refresh_from_storage method does its job
    $users_context->properties()->{beers} = 'NOTHING';
    is( $users_context->get_property('beers') , 'NOTHING' , "Fiddling with properties worked");

    $users_context->refresh_from_storage();
    is_deeply( $users_context->get_property('beers') , [ 'duvel' , 'chimay' ] , "Refreshing the context from storage pulled the right properties back again");

    cmp_ok( $users_context->fullname(), "eq" , "UNIVERSE/users" , "Ok good fullname for users");
    cmp_ok( $users_context->name() , 'eq' , 'users' , "Ok name is good");
    cmp_ok( $users_context->restricted()->name() , 'eq' , $universe->name() , "Ok restricted right context");
    ok( $users_context->has_property('pi') , "Ok can find pi in the restriction too");
    ok( $users_context->has_property('color') , "Ok users have property color");
    cmp_ok( $users_context->get_property('color') , "eq" , 'blue' , "Ok can get color from users");

    my $user1_ctx = $cm->restrict('users', '1');
    cmp_ok( $user1_ctx->name() , 'eq' , '1' , "Ok good name");
    ok( $user1_ctx->has_property('pi') , "Ok user 1 knows pi");
    ok( $user1_ctx->has_property('color') , "Ok user 1 knows color");
    cmp_ok( $user1_ctx->get_property('pi') , '==' , 3.14159 , "Ok can get pi from user 1");
    cmp_ok( $user1_ctx->get_property('color') , "eq" , 'blue' , "Ok can get color from user 1");

    my $user2_ctx = $cm->restrict('users', '2');
    cmp_ok( $user2_ctx->get_property('pi') , '==' , 3.14159 , "Ok can get pi from user 1");
    cmp_ok( $user2_ctx->get_property('color') , "eq" , 'black' , "Ok can get color black from user 2");


    my $lists = $cm->restrict('lists');
    my $list1 = $cm->restrict($lists, '1');

    my $u1l1 = $cm->unite($user1_ctx , $list1);
    cmp_ok( $u1l1->get_property('flavour') , 'eq' ,'apple' , "u1l1 has apple flavour");
    cmp_ok( $list1->get_property('flavour') , 'eq' , 'blueberry' , "Ok list 1 has blueberry");
    cmp_ok( $user1_ctx->get_property('flavour') , 'eq', 'banana' , "Ok user1 has got banana");
    is_deeply( $user1_ctx->lookup('beers')->delete_property('beers') , [ 'duvel' , 'chimay' ] , "Ok can delete beers from user1");
    ## Now its just stella for the universe.
    is_deeply( $user1_ctx->get_property('beers') , [ 'stella' ] , "Ok got only stella");
  }

}

## Check users_store and list stores are not empty.
ok( $users_store->resultset->count() , "Ok something is stored in the users_store");
ok( $general_store->resultset->count() , "Ok something is stored in the general store");
ok( $split_store->rule('default') , "Ok can get the default rule from the split store");

done_testing();
