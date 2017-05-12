use strict;
use warnings;

use Test::More tests => 1;
use Class::C3::XS;

BEGIN {
  package ClassA;
  our @ISA;
}
BEGIN {
  package ClassB;
  our @ISA;
}
BEGIN {
  package ClassC;
  our @ISA;
}
BEGIN {
  package ClassD;
  our @ISA = qw(ClassA ClassB);
}
BEGIN {
  package ClassE;
  our @ISA = qw(ClassA ClassC);
}
BEGIN {
  package ClassF;
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

is_deeply(
    [ Class::C3::XS::calculateMRO('ClassF') ],
    [ qw(ClassF ClassD ClassE ClassA ClassB ClassC) ],
    '... got the right MRO for ClassF');
