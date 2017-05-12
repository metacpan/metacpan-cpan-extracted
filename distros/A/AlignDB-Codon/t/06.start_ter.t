use strict;
use warnings;

use Test::More;
use AlignDB::Codon;

my $codon = AlignDB::Codon->new( table_id => 1 );

is( $codon->is_start_codon('ATG'), 1, 'is_start_codon, ATG' );
is( $codon->is_start_codon('GGH'), 0, 'is_start_codon, GGH' );
is( $codon->is_start_codon('CCC'), 0, 'is_start_codon, CCC' );

is( $codon->is_ter_codon('UAG'), 1, 'is_ter_codon, U should map to T, UAG' );
is( $codon->is_ter_codon('TaG'), 1, 'is_ter_codon,TaG' );
is( $codon->is_ter_codon('ttA'), 0, 'is_ter_codon,ttA' );

# (mbiguous codons should fail
is( $codon->is_ter_codon('NNN'), 0, 'is_ter_codon, ambiguous codons should fail, NNN' );
is( $codon->is_ter_codon('TAN'), 0, 'is_ter_codon, ambiguous codons should fail, TAN' );
is( $codon->is_ter_codon('CC'),  0, 'is_ter_codon, incomplete codons should fail, CC' );

done_testing();
