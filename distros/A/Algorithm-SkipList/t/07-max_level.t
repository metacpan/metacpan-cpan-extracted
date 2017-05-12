#-*- mode: perl;-*-

package main;

use strict;

use Test::More tests => 253;

use Algorithm::SkipList 0.70;

ok( Algorithm::SkipList::MIN_LEVEL == 2 );
ok( Algorithm::SkipList::MAX_LEVEL == 32 );

my $List;

undef $List;
eval {
  $List = new Algorithm::SkipList( max_level => 33 );
};
ok( !defined $List );

undef $List;
eval {
  $List = new Algorithm::SkipList( max_level => 1 );
};
ok( !defined $List );

undef $List;
eval {
  $List = new Algorithm::SkipList( max_level => 0 );
};
ok( !defined $List );

undef $List;
eval {
  $List = new Algorithm::SkipList( max_level => -1 );
};
ok( !defined $List );

for my $level (2..32) {
  undef $List;
  eval {
    $List = new Algorithm::SkipList( max_level => $level );
  };
  ok( defined $List );
  ok( $List->max_level == $level );

  my $size = ($level < 10) ? (1<<$level) : (1<<10);

  for (1..$size) { $List->insert($_); }
  ok( $List->max_level == $level );

  ok( $List->level == $List->list->level, "test level() method" ); 

  # This doesn't prove there's no error (since it's
  # non-deterministic), but it's worth checking anyway.

  ok( $List->list->level <= $level );

  $List->max_level( $List->list->level );
  ok( $List->list->level == $List->max_level );

  eval { $List->max_level( $List->list->level-1); };
  ok( $List->list->level == $List->max_level );

  if ($level > 2) {
    eval { $List->max_level($level-1); };
    ok(
       ($List->list->level == $level) ?
       $List->max_level != ($level-1) :
       $List->max_level == ($level-1)
      );
  }
}
