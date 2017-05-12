$| = 1; print "1..3000\n";

no warnings;
use Array::Heap;

srand 0;

my @x = map [$_], 1..10, map rand, 1..100;
my $err;

my @test = (
   sub { push_heap_idx                 @x, [rand] },
   sub { push_heap_idx                 @x, [1 + rand], [3 + rand] },
   sub { pop_heap_idx                  @x },
   sub { splice_heap_idx               @x, int rand @x },
);

sub chk {
   for (1 .. $#x) {
      if (!($x[$_][0] > $x[($_ - 1) >> 1][0])) {
         $err = "cmp \$x[$_] ($x[$_]) !> \$x[$_ >> 1] ($x[($_ - 1) >> 1])";
         make_heap_idx @x;
      }
   }
   for (0 .. $#x) {
      if ($x[$_][1] != $_) {
         $err = "idx $_ != $x[$_][1]";
         $x[$_][1] = $_;
      }
   }
}

make_heap_idx @x;
chk;

for (1..3000) {
   undef $err;
   my $t = int rand @test;
   $test[$t]->();
   chk;
   print defined $err ? "not " : "", "ok $_ # $t,$err\n";
}
