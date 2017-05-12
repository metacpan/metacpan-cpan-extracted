
use strict;
use warnings;

use Benchmark::CSV;
use Path::Tiny;
use FindBin;

chdir $FindBin::Bin;

my $outfile   = path($FindBin::Bin)->child("out.csv");
my $imagefile = path($FindBin::Bin)->child("math.png");
my $histfile  = path($FindBin::Bin)->child("math_histogram.png");

my $bench = Benchmark::CSV->new(
  sample_size => 10_000,
  output      => $outfile,
);

my $rint        = '(int(rand(32768)) + 1)';
my $rint_small  = '(int(rand(32768)) + 1)';
my $nrint       = '(0 - int(rand(32768)) + 1)';
my $nrint_small = '(0 - int(rand(32768)) + 1)';

if ( $ENV{DOUBLE_RANDOM} ) {
  $bench->add_instance( 'small: x + y' => eval qq[ sub { $rint_small + $rint_small } ] );
  $bench->add_instance( 'large: x + y' => eval qq[ sub { $rint + $rint } ] );
  $bench->add_instance( 'small: x - y' => eval qq[ sub { $rint_small - $rint_small } ] );
  $bench->add_instance( 'large: x - y' => eval qq[ sub { $rint - $rint } ] );

  if ( $ENV{ALL} ) {
    $bench->add_instance( 'x * y'  => eval qq[ sub { $rint * $rint } ] );
    $bench->add_instance( 'x + -y' => eval qq[ sub { $rint + $nrint } ] );
    $bench->add_instance( 'x - -y' => eval qq[ sub { $rint - $nrint } ] );
    $bench->add_instance( 'x ** y' => eval qq[ sub { $rint ** $rint } ] );
    $bench->add_instance( 'x / y'  => eval qq[ sub { $rint / $rint } ] );
  }

}
elsif ( $ENV{SINGLE_RANDOM} ) {
  $bench->add_instance( 'small: x + 1' => eval qq[ sub { $rint_small + 1 } ] );
  $bench->add_instance( 'large: x + 1' => eval qq[ sub { $rint + 1 } ] );
  $bench->add_instance( 'small: x - 1' => eval qq[ sub { $rint_small - 1 } ] );
  $bench->add_instance( 'large: x - 1' => eval qq[ sub { $rint - 1 } ] );

  if ( $ENV{ALL} ) {
    $bench->add_instance( 'x * 1'  => eval qq[ sub { $rint * 1 } ] );
    $bench->add_instance( 'x + -1' => eval qq[ sub { $rint +  -1 } ] );
    $bench->add_instance( 'x - -1' => eval qq[ sub { $rint - -1 } ] );
    $bench->add_instance( 'x ** 1' => eval qq[ sub { $rint ** 1 } ] );
    $bench->add_instance( 'x / 1'  => eval qq[ sub { $rint / 1 } ] );
  }
}
else {
  my $large = 97531;
  my $small = 254;
  $bench->add_instance( 'small: x + 1' => sub { $small + 1 } );
  $bench->add_instance( 'large: x + 1' => sub { $large + 1 } );
  $bench->add_instance( 'small: x - 1' => sub { $small - 1 } );
  $bench->add_instance( 'large: x - 1' => sub { $large - 1 } );
  if ( $ENV{ALL} ) {
    $bench->add_instance( 'x * 1'  => sub { $large * 1 } );
    $bench->add_instance( 'x + -1' => sub { $large + -1 } );
    $bench->add_instance( 'x - -1' => sub { $large - -1 } );
    $bench->add_instance( 'x ** 1' => sub { $large**1 } );
    $bench->add_instance( 'x / 1'  => sub { $large / 1 } );
  }

}

*STDERR->print("Running benchmark\n");
*STDERR->autoflush(1);
my $steps = 50;
*STDERR->print( q{[} . ( q[ ] x $steps ) . qq{]\r[} );
for ( 1 .. $steps ) {
  $bench->run_iterations( 10_000_000 / $steps );
  *STDERR->print("#");
}
*STDERR->print("]\n");
*STDERR->print("Generating plot\n");
system( "gnuplot", "plot.gnuplot" );
*STDERR->print("$imagefile\n");
*STDERR->print("Collating histogram data\n");
system( $^X, './aggregate.pl' );
*STDERR->print("Generating histogram plot\n");
system( 'gnuplot', 'aggregate_histogram.gnuplot' );
*STDERR->print("$histfile\n");

