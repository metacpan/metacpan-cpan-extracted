
use strict;
use warnings;

use Test::More tests => 4;

# ABSTRACT: Test basic performance

use Benchmark::CSV;
use Path::Tiny;

my $tdir = Path::Tiny->tempdir;

my $csv = $tdir->child('out.csv');

my $bench = Benchmark::CSV->new(
  sample_size => 100,
  output      => $csv,
);

my $x = 946744;
my $y = 7;

$bench->add_instance( 'x + y' => sub { $x + $y } );
$bench->add_instance( 'x - y' => sub { $x - $y } );

$bench->run_iterations(100_000);

my $lines = [ $csv->lines( { chomp => 1 } ) ];
is( $lines->[0], 'x + y,x - y', "Header in place" );
like( $lines->[1],  qr/\A\d+[.]\d+,\d+[.]\d+/msx, "Second line matches regex" );
like( $lines->[-1], qr/\A\d+[.]\d+,\d+[.]\d+/msx, "Last line matches regex" );
is( scalar @{$lines}, 1001, "Has 1 line per sample + header" );
