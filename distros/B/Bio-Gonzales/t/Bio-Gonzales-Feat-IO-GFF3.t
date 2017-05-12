use warnings;
use Data::Dumper;
use Test::More skip_all => 'FIXME';

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing Bio::Gonzales::Feat::IO::GFF3" if $@;

  use_ok("Bio::Gonzales::Feat::IO::GFF3");
}

my $d;
sub TEST { $d = $_[0]; }
#TESTS

TEST 'load gff';
{
  my $gff = Bio::Gonzales::Feat::IO::GFF3->new( file => 't/test.gff3' );

  my $gffout = Bio::Gonzales::Feat::IO::GFF3->new( fh => \*STDERR, mode => '>', pragmas => $gff->pragmas );

  while ( my $z = $gff->next_feat ) { $gffout->write_feat($z); }
}
