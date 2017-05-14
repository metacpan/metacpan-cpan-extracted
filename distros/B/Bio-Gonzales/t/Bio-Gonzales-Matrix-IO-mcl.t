use warnings;
use Test::More skip_all => 'deprecated, develop new with my mio pkg';

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing Bio::Gonzales::Feat::IO::GFF3" if $@;

  use_ok('Bio::Gonzales::Matrix::IO::mcl');
}

my $d;
sub TEST { $d = $_[0]; }

#TESTS
my $parser = Bio::Matrix::IO->new(
  -format => 'phylip',
  -file   => 't/Matrix-IO-mcl_phylip.distances'
);

my $writer = Bio::Matrix::IO->new( -format => '+Bio::Gonzales::Matrix::IO::mcl', -fh => \*STDERR );
TEST 'intermediate result filename';
{
  diag $writer->write_matrix( $parser->next_matrix );

}
