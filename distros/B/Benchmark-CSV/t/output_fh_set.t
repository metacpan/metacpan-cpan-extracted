
use strict;
use warnings;

use Test::More tests => 6;

# ABSTRACT: Test basic performance

use Benchmark::CSV;
use Path::Tiny;

my $tdir = Path::Tiny->tempdir;

my $csv = $tdir->child('out.csv');

{
  my $bench = Benchmark::CSV->new( { sample_size => 100, } );
  $bench->output_fh( \*STDERR );

  pass("Set output did not fail");
}
{
  my $bench = Benchmark::CSV->new( { sample_size => 100, } );
  ok( defined $bench->output_fh(), 'got a defined fh when one wasnt passed and no output set' );
}
{
  my $string = "";
  open my $fh, '>', \$string;
  my $bench = Benchmark::CSV->new( { sample_size => 100, output_fh => $fh } );
  ok( defined $bench->output_fh(), 'got a defined fh' );
  $bench->output_fh->print("Test");
  is( $string, "Test", "String written to" );
}
{
  my $bench = Benchmark::CSV->new( { sample_size => 100, } );
  ok( defined $bench->output_fh(), 'got a defined fh when one wasnt passed and no output set' );
  $bench->{finalized} = 1;
  local $@;
  my $err = eval {
    $bench->output_fh( \*STDERR );
    1;
  };
  isnt( $err, 1, "Setting output_fh after finalized should fail" );

}
