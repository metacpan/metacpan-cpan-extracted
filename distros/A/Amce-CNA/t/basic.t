
use strict;
use warnings;

use Test::More tests => 9;

{
  package Thing;
  sub does_stuff { return "Stuff done!"; }
}

my $x = eval { Thing->deos_stuff };
my $e = $@;

is($x, undef, "the thing doesn't do stuff");
like($e, qr/object method/, "throws exception");

{
  package Thing;
  require Amce::CNA;
  Amce::CNA->import;
}

{
  my $x = eval { Thing->deos_stuff };
  my $e = $@;

  is($x, "Stuff done!", "the thing doesn't do stuff");
  ok(!$e, "no exception");
}

{
  package Parent;
  require Amce::CNA;
  Amce::CNA->import;

  sub live { return 1 };

  package Child;
  our @ISA = qw(Parent);

  sub evil { return 666 };
}

{
  my $x = Parent->live;
  is($x, 1, "parent lives!");

  $x = Parent->evil;
  is($x, 1, "parent lievs!");

  $x = Child->evil;
  is($x, 666, "chlid elvi!");

  $x = Child->live;
  is($x, 1, "dlcih eliv!");
}

ok(Child->can('vile'), "child can live");
