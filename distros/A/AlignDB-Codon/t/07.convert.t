use strict;
use warnings;

use Test::More;
use AlignDB::Codon;

my $codon = AlignDB::Codon->new( table_id => 1 );

is( $codon->convert_123("A"), "Ala", 'convert_123, A -> Ala' );
is( $codon->convert_321("Pro"), "P", 'convert_321, Pro -> P' );

done_testing();
