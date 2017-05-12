#!perl
use Test::More;
use B qw(class);
use B::Utils1 qw( all_roots walkoptree_simple);

my @lines = ();
my $callback = sub {
  my $op = shift;
  # collect existing cops, and also perl specific optimized away cops
  if (($op->isa('B::NULL') and $B::Utils1::file eq __FILE__ and $B::Utils1::trace_removed)
      or ('COP' eq B::class($op) and $op->file eq __FILE__)) {
    if ('COP' eq B::class($op)
        or (!$op->isa('B::NULL') and $op->oldname =~ /^(next|db)state$/)) {
      push @lines, $op->line;
    }
  }
};

foreach my $op (values %{all_roots()}) {
  walkoptree_simple( $op, $callback );
}

my $expected = $] >= 5.008
  ? [6, 17, 19, 19, 20, 23, 27, 32, 33, 35, 38, 39]
  : [6, 17, 19, 19, 20, 19, 23, 27, 32, 33, 35, 38, 39]; # more cops in 5.6

is_deeply(\@lines, 
          $expected,
          'walkoptree_simple lines of ' . __FILE__);

# For testing following if/else in code
if (@lines) {
  ok(1, "if/else folding");
} else {
  ok(0, "invalid if/else folding");
}

diag join(', ', @lines), "\n";
done_testing();

