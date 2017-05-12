#-*- mode: perl;-*-

package main;

use strict;

use Test::More tests => 19;

use Algorithm::SkipList 0.70;


my $List;

undef $List;
eval {
  $List = new Algorithm::SkipList( p => 0 );
};
ok( !defined $List, "test p cannot be set to 0" );

undef $List;
eval {
  $List = new Algorithm::SkipList( p => 1 );
};
ok( !defined $List, "test p cannot be set to 1" );

undef $List;
eval {
  $List = new Algorithm::SkipList( p => -1 );
};
ok( !defined $List, "test p cannot be set to negative" );

for my $i (1..8) {

  my $p = 1 / (1<<$i);

  undef $List;
  $List = new Algorithm::SkipList( p => $p );
  ok( $List->p == $p, "test p was set to custom value" );

  $List->p( $p/2 );
  ok( $List->p == ($p/2), "test setting p on existing skip list" );
}
