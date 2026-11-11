#!perl                                                      #  make sure to fix
use Test::More 0.88;                                        #  line numbers
                                                            #  for any line
                                                            #  identified
use B qw(class);                                            #  as an op!
use B::Utils qw( all_roots walkoptree_simple);

my @lines = ();                                             #  8  op
my $callback = sub                                          #  9  op
{
  my $op = shift;
  if ('COP' eq B::class($op) and  $op->file eq __FILE__) {
    push @lines, $op->line; # includes ex-nextstate COPs
  }
};                                                          # 15  op

foreach my $op (values %{all_roots()}) {                    # 17  op
  walkoptree_simple( $op, $callback );                      # 18  op
}
my $expected = [8, 9, 17, 17, 18, 20, 22, 23, 25, 26, 28, 29, 32, 37, 38, 40, 43]; # 20  op

if ("$]" < 5.045004) {                                      # 22  op
  $expected =  [8, 15, 17, 17, 18, 20, 22, 23, 25, 26, 28, 29, 32, 37, 38, 40, 43]; # 23  op
}
if ("$]" < 5.045003) {                                      # 25  op
  $expected =  [8, 15, 17, 17, 18, 20, 22, 23, 25, 26, 28, 29, 32, 37, 38, 40, 43]; # 26 op
}
if ("$]" < 5.007) {                                         # 28  op
  $expected =  [8, 15, 17, 17, 18, 17, 20, 22, 23, 25, 26, 28, 29, 32, 37, 38, 40, 43]; # 29 op
}

is_deeply(\@lines,                                          # 32  op
          $expected,
          'walkoptree_simple lines of ' . __FILE__);

# For testing following if/else in code.
if (@lines) {                                               # 37  op
  ok(1);                                                    # 38  op
} else {
  ok(0);                                                    # 40  op
}

done_testing();                                             # 43  op
__END__
diag join(', ', @lines), "\n";
