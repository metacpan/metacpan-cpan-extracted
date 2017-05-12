#!perl
use warnings;
use strict;
use Test::More no_plan => 1;
use FindBin;

use lib "$FindBin::Bin/lib";
use Tuit;
use Limb;

require "$FindBin::Bin/lib/setup_dbs.pl";

test_sub_with_dbs (undef, sub {
  my ($dbh, $name) = @_;
  Class::Persist->dbh($dbh);

  ok(Tuit->create_table, "$name: created table ".Tuit->db_table);
  ok(Limb->create_table, "$name: created table ".Limb->db_table);

  foreach my $ord (78, 175, 175, 256) {
    ok(my $test = Tuit->new, "created new test object");

    ok($test->Colour(chr $ord), "set Colour");
    ok($test->store, "stored object");

    my @all = Tuit->get_all;
    is(scalar(@all), 1, "One object in the database");

    my $got = $all[0];
    my $colour = $got->Colour();
    is(length $colour, 1, "1 char");
    is(ord $colour, $ord, "1 char is chr $ord");

    $got->Colour(" " . chr $ord);
    ok($got->store, "update stored object");

    @all = Tuit->get_all;
    is(scalar(@all), 1, "Still object in the database");

    $got = $all[0];
    $colour = $got->Colour();
    is(length $colour, 2, "2 char");
    is(ord $colour, ord " ", "1st char is a space");
    is(ord (substr $colour, 1), $ord, "2nd char is chr $ord");
    $test->delete();
  }

  my $latin = "bl".chr(233)."u"; # e-acute;
  my $unicode = "bl".chr(195).chr(169)."u";
  use Encode; Encode::_utf8_on($unicode);

  ok( my $test = Tuit->new({ Colour => $latin }), "created utf8 object" );
  ok( $test->store, "stored" );
  ok( Tuit->load( Colour => $latin ), "retrieved based on colour" );
  ok( Tuit->load( Colour => $unicode ), "retrieved based on colour" );


  use Storable qw( nfreeze thaw );
  my $brain = { pie => 'tasty', buffy => 'pony' };
  ok( my $frozen_brains = nfreeze( $brain ), "frozen brains" );
  ok( my $head = Limb->new, "got a new head" );
  ok( $head->brain_contents( $frozen_brains ), "set brain_contents" );
  ok( $head->store, "stored" );
  ok( my $other_head = Limb->load( $head->oid ), "got anotther copy of the head" );
  ok( my $test_brains = thaw( $head->brain_contents ), "thawed brains" );
  is_deeply( $brain, $test_brains, "the brains are the same" );
  
  

});
