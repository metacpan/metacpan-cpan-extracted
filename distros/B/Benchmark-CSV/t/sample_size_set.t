
use strict;
use warnings;

use Test::More tests => 3;

# ABSTRACT: Test basic performance

use Benchmark::CSV;
use Path::Tiny;

my $tdir = Path::Tiny->tempdir;

my $csv = $tdir->child('out.csv');

{
  my $bench = Benchmark::CSV->new( { sample_size => 100, } );

  $bench->sample_size(10);

  pass("Set sample_size did not fail");
}
{
  my $bench = Benchmark::CSV->new( {} );
  my $ss = $bench->sample_size();
  is( $ss, '1', 'default sample size' );
}
{
  local $@;
  my $bench = Benchmark::CSV->new( { sample_size => 100, } );
  $bench->{finalized} = 1;

  my $er = eval {
    $bench->sample_size(10);
    1;
  };

  isnt( $er, 1, "Setting sample size once finalised should bail" );

}
