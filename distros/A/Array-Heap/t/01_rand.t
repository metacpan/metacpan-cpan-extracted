$| = 1; print "1..3000\n";

no warnings;
use Array::Heap;

srand 0;

my @x = (1..10, map rand, 1..100);
my $err;

my @test = (
   sub { push_heap_cmp   { $a <=> $b } @x, rand },
   sub { push_heap                     @x, rand },
   sub { push_heap_cmp   { $a <=> $b } @x, 1 + rand, 3 + rand},
   sub { push_heap                     @x, 1 + rand, 3 + rand},
   sub { pop_heap_cmp    { $a <=> $b } @x },
   sub { pop_heap                      @x },
   sub { splice_heap_cmp { $a <=> $b } @x, int rand @x },
   sub { splice_heap                   @x, int rand @x },
);

sub chk {
   for (1 .. $#x) {
      if (!($x[$_] > $x[($_ - 1) >> 1])) {
         $err = "\$x[$_] ($x[$_]) !> \$x[$_ >> 1] ($x[($_ - 1) >> 1])";
         make_heap @x;
      }
   }
}

make_heap @x;
chk;

for (1..3000) {
   undef $err;
   my $t = int rand @test;
   $test[$t]->();
   chk;
   print defined $err ? "not " : "", "ok $_ # $t,$err\n";
}
