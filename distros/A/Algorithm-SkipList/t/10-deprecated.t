#-*- mode: perl;-*-

use Test::More tests => 4;
use Test::Warn;

warning_like {
  use_ok("List::SkipList");
} qr/The List::SkipList namespace is deprecated; use Algorithm::SkipList/,
  "deprecated namespace warning";

my $List = new List::SkipList;
ok( $List->isa('List::SkipList'),      'isa List::SkipList' );
ok( $List->isa('Algorithm::SkipList'), 'isa Algorithm::SkipList' );


