use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
  package ClassA;
  use Class::C3;
}
BEGIN {
  package ClassB;
  use Class::C3;
}
BEGIN {
  package ClassC;
  use Class::C3;
}
BEGIN {
  package ClassD;
  use Class::C3;
  our @ISA = qw(ClassA ClassB);
}
BEGIN {
  package ClassE;
  use Class::C3;
  our @ISA = qw(ClassA ClassC);
}
BEGIN {
  package ClassF;
  use Class::C3;
  our @ISA = qw(ClassD ClassE);
}

=pod

From the parrot test t/pmc/object-meths.t

 A   B A   C
  \ /   \ /
   D     E
    \   /
     \ /
      F

=cut

Class::C3::initialize();

is_deeply(
    [ Class::C3::calculateMRO('ClassF') ],
    [ qw(ClassF ClassD ClassE ClassA ClassB ClassC) ],
    '... got the right MRO for ClassF');
