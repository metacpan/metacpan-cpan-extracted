
use strict;
use warnings;

use Benchmark::CSV;
use Path::Tiny;
use List::Util qw( shuffle );
use FindBin;

chdir $FindBin::Bin;

my $outfile   = path($FindBin::Bin)->child("out.csv");
my $imagefile = path($FindBin::Bin)->child("shuffle.png");

my $bench = Benchmark::CSV->new(
  sample_size => 200,
  output      => $outfile,
);

my @source_keys = map { $_ . ' of Spades', $_ . ' of Clubs', $_ . ' of Diamonds', $_ . ' of Hearts' }
  qw( Ace 2 3 4 5 6 7 8 9 10 Jack Queen King );
my %source_hash       = map { $_ => 1 } @source_keys;
my %source_hash_clean = map { $_ => 1 } @source_keys;

$bench->add_instance(
  'shuffle' => sub {
    my @out = shuffle(@source_keys);
    1;
  }
);
$bench->add_instance(
  'hash trick' => sub {
    { local $source_hash{_peturb} = 1; };
    my @out = keys %source_hash;
    1;
  }
);
$bench->add_instance(
  'shuffle keys' => sub {
    my @out = shuffle keys %source_hash_clean;
    1;
  }
);
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
