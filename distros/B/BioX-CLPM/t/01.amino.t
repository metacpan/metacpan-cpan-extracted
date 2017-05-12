use Test::More tests => 2;

BEGIN {
use_ok( 'BioX::CLPM::Amino' );
}

my $amino   = BioX::CLPM::Amino->new({ amino_acid_id => 1 });
my $letter  = $amino->get_amino_acid_id(); 
ok( $letter, 'Amino acid found' );

