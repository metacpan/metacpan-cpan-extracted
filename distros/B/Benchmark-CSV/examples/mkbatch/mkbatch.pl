
use strict;
use warnings;

use Benchmark::CSV;
use Path::Tiny;
use FindBin;

chdir $FindBin::Bin;

my $outfile   = path($FindBin::Bin)->child("out.csv");
my $imagefile = path($FindBin::Bin)->child("mkbatch.png");

my $bench = Benchmark::CSV->new(
  sample_size => 100,
  output      => $outfile,
);

my $noop = sub { };

my $iter_a = join qq[\n], map { '$noop->();' } 0 .. 100;
my $code_a;
my $code_b;

local $@;
eval <<"EOF" or die $@;
\$code_a = sub {
  1;
  $iter_a
  1;
};
1;
EOF

eval <<"EOF" or die $@;
\$code_b = sub {
  1;
  for ( 0 .. 100 ) {
    \$noop->();
  }
  1;
};
1
EOF

$bench->add_instance( 'unrolled' => $code_a );
$bench->add_instance( 'loop'     => $code_b );
*STDERR->print("Running benchmark\n");
*STDERR->autoflush(1);
my $steps = 50;
*STDERR->print( q{[} . ( q[ ] x $steps ) . qq{]\r[} );
for ( 1 .. $steps ) {
  $bench->run_iterations( 1_000_000 / $steps );
  *STDERR->print("#");
}
*STDERR->print("]\n");
*STDERR->print("Generating plot\n");
system( "gnuplot", "plot.gnuplot" );
*STDERR->print("$imagefile\n");
