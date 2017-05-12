
use strict;
use warnings;

use Benchmark::CSV;
use Path::Tiny;
use List::Util qw( shuffle );
use FindBin;

chdir $FindBin::Bin;

my $outfile   = path($FindBin::Bin)->child("out.csv");
my $imagefile = path($FindBin::Bin)->child("vs_benchmark_pm.png");

my (@slaves);

# Spin up CPU Heaters.
for ( 0 .. 3 ) {
  my $pid = fork;
  if ($pid) {
    push @slaves, $pid;
    next;
  }
  while (1) {
    my $pos = rand() / rand();
  }
}

END {
  for my $slave (@slaves) {
    kill 'HUP', $slave;
  }
}

my $bench = Benchmark::CSV->new(
  sample_size => 10_000,
  output      => $outfile,

  #  scale_values => 1,
  #  per_second   => 1,
);

$bench->add_instance(
  'a' => sub {
    my $pos = 1 + rand(255);
    1;
  }
);
$bench->add_instance(
  'b' => sub {
    my $pos = 1 + rand(255) + rand(255);
    1;
  }
);
*STDERR->print("Running benchmark\n");
*STDERR->autoflush(1);
my $steps = 10;
my $its   = 5_000_000 / $steps;

#$bench->{timing_method} = 'hires_cputime_thread';

$bench->{timing_method} = 'times';

*STDERR->print( q{[} . ( q[ ] x $steps ) . qq{]\r[} );
for ( 1 .. $steps ) {
  $bench->run_iterations($its);
  *STDERR->print("#");
}
*STDERR->print("]\n");

for my $slave (@slaves) {
  kill 'HUP', $slave;
}
if ( $ENV{RUN_TWO} ) {
  *STDERR->print( q{[} . ( q[ ] x $steps ) . qq{]\r[} );
  for ( 1 .. $steps ) {
    $bench->run_iterations($its);
    *STDERR->print("#");
  }
  *STDERR->print("]\n");
}
*STDERR->print("Generating plot\n");
system( "gnuplot", "plot.gnuplot" );
*STDERR->print("$imagefile\n");
