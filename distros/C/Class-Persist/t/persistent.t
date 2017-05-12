#!perl
use warnings;
use strict;
use Test::More no_plan => 1;
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/lib";
use Tuit;
use Limb;
use Arm;


require "$FindBin::Bin/lib/setup_dbs.pl";

test_sub_with_dbs (undef, sub {
  my ($dbh, $name) = @_;
  Class::Persist->dbh($dbh);

  ok(Tuit->create_table, "$name: created table ".Tuit->db_table);
  ok(Limb->create_table, "$name: created table ".Limb->db_table);
  ok(Arm->create_table,  "$name: created table ".Arm->db_table);


  ok(my $test = Tuit->new, "created new test object");
  ok(!$test->_from_db(), "new test object is not from DB");
  ok($test->Colour('Orange'), "set Colour");
  ok($test->Mass(42), "set Mass");
  ok($test->store, "stored object");
  ok($test->_from_db(), "new test object should now report itself as from DB");
  my $id = $test->oid();

  is(scalar(Tuit->get_all), 1, "Now one object in the database");

  ok($test = Tuit->new, "created another new test object");
  ok(!$test->_from_db(), "new test object is not from DB");
  ok($test->Colour('Purple'), "set Colour");
  ok($test->Mass(7), "set Mass");
  ok($test->store, "stored object");

  is(scalar(Tuit->get_all), 2, "Now two objects in the database");

  ok(my @get = Tuit->search( Colour => 'Purple' ), "got search results");
  #isa_ok($get[0], "Class::Persist::Proxy", "got a proxy object");
  is(@get, 1, "there's only one result");
  my $purple = $get[0];
  is($purple->Mass, 7, "it's the right result");
  isa_ok($purple, "Tuit", "got a deproxyfied object");
  ok($purple->_from_db(), "it came from outer space^W^Wthe DB");

  is(@get = Tuit->search( Colour => 'Grey' ), 0, "No grey tuits");

  is(@get = Tuit->sql( 'Colour = ?', 'Purple' ), 1, "There's a purple one, sure..");
  is(@get = Tuit->sql( 'Colour = ?', 'Grey' ), 0, "..but no grey tuits");

  my $old_oid = $purple->oid;
  ok($purple->delete(), "Delete the purple tuit");
  ok(!($purple->_from_db()), "not longer from DB");
  ok( my $deleted = Class::Persist::Deleted->load( $old_oid ), "but is deleted" );
  is( $deleted->object->Colour, "Purple", "still purple, even in death" );

  is(scalar(Tuit->get_all), 1, "Now one object in the database");

  ok(@get = Tuit->search( $Class::Persist::ID_FIELD => $id ), "got search results for $id");
  #isa_ok($get->[0], "Class::Persist::Proxy", "got a proxy object");
  is(@get, 1, "there's only one result");
  my $orange = $get[0];
  is ($orange->Colour(), 'Orange', "And it's orange");
  ok($orange->_from_db(), "from DB");

  ok( my $orange2 = $orange->clone , "cloned object" );
  ok( $orange2->oid ne $orange->oid, "clone has a new oid"  );
  ok(!($orange2->_from_db()), "clone is not from DB");
  ok( $orange2->store, "stored it" );
  ok($orange2->_from_db(), "is from DB one we store it");
  is(scalar(Tuit->get_all), 2, "Now two objects in the database");

  is(@get = Tuit->advanced_search(
    "SELECT $Class::Persist::ID_FIELD from ".Tuit->db_table.' WHERE Colour = ?', 'Grey'
  ), 0, "still no grey tuits though");
  
  ok( my $invisible = Tuit->new( Mass => 1 ), "created massy yet invisible tuit" );
  ok( $invisible->store, "and stored it" );
  is( scalar( Tuit->search( Colour => undef ) ), 1, "It can't hide from us, though." );

  ok( my $limb = Limb->new, "created a new limb" );
  ok( $limb->tuit( $invisible ), "..with an invisible tuit" );
  ok( $limb->digits( 5 ), "..and 5 digits" );
  ok( $limb->store, "stored" );
  isa_ok( $limb->tuit, "Class::Persist::Proxy", "Tuit was proxied" );
  is( $limb->digits, 5, "still has 5 digits" );

  isa_ok( $limb->tuits, "Class::Persist::Proxy::Collection", "tuits is a container" );
  is( scalar @{$limb->tuits}, 0, "no tuits" );
  ok( $limb->tuits->push( $purple ), "added one" );
  is( scalar @{$limb->tuits}, 1, "1 tuit" );
  ok( $limb->store, "stored" );
  is( scalar @{$limb->tuits}, 1, "1 tuit" );
  ok( $limb->tuits->load );
  is( scalar @{$limb->tuits}, 1, "1 tuit" );
  is( Limb->load( $limb->oid )->tuits->count, 1, "1 tuit");

  is( $limb->tuits->[0]->owner->oid, $limb->oid, "tuits owned by limb");

  ok( my $arm = Arm->new( side => "left", preferred => 1, elbows => 1 ), "created arm" );
  ok( $arm->store, "stored" );

  is( $arm->side, 'left', "side is left" );
  ok( $arm->side( 'right' ), "changed side" );
  is( $arm->side, 'right', "side is right" );
  ok( $arm->revert, "reverted" );
  is( $arm->side, 'left', "side is left" );

  ok(Tuit->drop_table, "dropped table");
  ok(Limb->drop_table, "dropped table");
  ok(Arm->drop_table, "dropped table");
});
