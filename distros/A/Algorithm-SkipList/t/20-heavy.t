#-*- mode: perl;-*-

package main;

use strict;
use warnings;

# use Pod::Coverage package => 'Algorithm::SkipList';

# These tests are redundant, but they are useful for "heavy" testing
# to find rare errors (since this is a non-deterministic algorithm)
# and for some informal benchmark comparisons.

# For "heavy" testing, change size to a larger value (100 or 1,000 or 10,000).

use constant SIZE => 20;

use Test::More tests => 6+(53*SIZE);

use Test::Warn;

use_ok("Algorithm::SkipList");

ok($Algorithm::SkipList::VERSION >= 1.02);

my @Keys = ();
my $Cnt  = SIZE;

my $Stuff = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

sub random_stuff {
  my $len ||= 8;
  my $thing = "";
  for(1..$len) {
    $thing .= substr($Stuff, int(rand(length($Stuff))),1);
  }
  return $thing;
}

my %Hash  = ();
my %Bogus = ();
my $List  = new Algorithm::SkipList;

{
  no warnings;
  ok(!defined $List->first_key);
}

foreach (1..SIZE) {
  my $k;
  do {
    $k = random_stuff();
  } while (exists $Bogus{ $k });

  my $v = random_stuff();

  $Hash{ $k } = $v;

  my $a; # alternate value
  do {
    $a = random_stuff();
  } while ($a eq $v);

  my $x;
  do {
    $x = random_stuff();
  } while (exists $Hash{ $v });

  $Bogus{ $x } = $a;

  ok( $List->list->key_cmp($k) == -1 );
  warnings_are {
    ok( !defined $List->list->key );
  } {carped => "this method should never be run"}, "header accessor warning";

  warnings_are {
    ok( !defined $List->list->value );
  } {carped => "this method should never be run"}, "header accessor warning";

  warnings_are {
    $List->list->value($a);
  } {carped => "this method should never be run"}, "header accessor warning";

  warnings_are {
    ok( !defined $List->list->value );
  } {carped => "this method should never be run"}, "header accessor warning";

#   ok( $Algorithm::SkipList::NULL->key_cmp($k) == 1 );
#   ok( !defined $Algorithm::SkipList::NULL->key );
#   ok( !defined $Algorithm::SkipList::NULL->value );
#   $Algorithm::SkipList::NULL->value($a);
#   ok( !defined $Algorithm::SkipList::NULL->value );
#   ok( $Algorithm::SkipList::NULL->level == 0 );
#   ok( !defined $Algorithm::SkipList::NULL->header );


  my $finger = $List->insert( $k, $a );
  ok( $List->size == scalar(keys %Hash) );

  ok( $List->exists( $k ) );
  ok( $List->find( $k ) eq $a );
  ok( $List->find_with_finger( $k ) eq $a );

  $finger = $List->insert( $k, $v, $finger );
  ok( $List->size == scalar(keys %Hash) );
  ok( $List->find( $k )eq $v );
  ok( $List->find_with_finger( $k ) eq $v );

  ok( $List->exists( $k, $finger ) );
  ok( $List->find( $k, $finger ) eq $v );
  ok( $List->find_with_finger( $k, $finger ) eq $v );

  {
    my ($node, $finger, $cmp) = $List->_search_with_finger($k);
    ok( $cmp == 0 );
    ok( $node->key_cmp($k) == 0 );
    ok( $node->key eq $k );
    ok( $node->value eq $v );

    ($node, $finger, $cmp) = $List->_search_with_finger($k, $finger);
    ok( $cmp == 0 );
    ok( $node->key_cmp($k) == 0 );
    ok( $node->key eq $k );
    ok( $node->value eq $v );
  }

  {
    my ($node, $finger, $cmp) = $List->_search($k);
    ok( $cmp == 0 );
    ok( $node->key_cmp($k) == 0 );
    ok( $node->key eq $k );
    ok( $node->value eq $v );

    ($node, $finger, $cmp) = $List->_search($k, $finger);
    ok( $cmp == 0 );
    ok( $node->key_cmp($k) == 0 );
    ok( $node->key eq $k );
    ok( $node->value eq $v );
  }

  my @results = $List->find( $k, $finger );
  ok( @results == 1 );
  ok( $results[0] eq $v );

  @results = $List->find_with_finger( $k, $finger );
  ok( @results == 2 );
  ok( $results[0] eq $v );
  ok( ref( $results[1] ) eq "ARRAY" );

  my $xkey  = $List->find( $x );
  ok( !defined $xkey );

  @results = $List->find( $x );
  ok( @results == 1 );
  ok( !defined $results[0] );

  $xkey  = $List->find_with_finger( $x );
  ok( !defined $xkey );

  @results = $List->find_with_finger( $x );
  ok( @results == 1 );
  ok( !defined $results[0] );

}

my $Copy = $List->copy();
ok( $List->size == $Copy->size );

foreach my $key (sort keys %Hash) {
  ok($key eq $List->next_key);
  ok($key eq $Copy->next_key);
}

foreach my $key (sort keys %Hash) {
  ok($key eq $Copy->first_key);
  ok(defined $Copy->delete($key));
  {
    # In v0.71_02, we changed the behavior so that deletes reset last key
    no warnings;
    ok($Copy->next_key ne $key);
  };
}

{
  my $sz = $List->size();
  foreach my $key (keys %Bogus) {
    no warnings;
    ok( !defined $List->delete( $key ) );
  }
  ok($List->size == $sz);
}

foreach my $key (keys %Hash) {
  my $sz = $List->size;
  ok( $List->delete( $key ) eq $Hash{$key} );
  ok( $List->size == $sz-1 );
}

ok($List->size == 0);

