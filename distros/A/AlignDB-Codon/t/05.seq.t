use strict;
use warnings;

use Test::More;

use AlignDB::Codon;

my $codon = AlignDB::Codon->new( table_id => 1 );

my $dna = "CGACGTCTTCGTACGGGACTAGCTCGTGTCGGTCGC";
my $pep = "RRLRTGLARVGR";

is( $codon->translate($dna), $pep, "translate full" );
is( $codon->translate( substr( $dna, 0, length($dna) - 1 ) ),
    substr( $pep, 0, length($pep) - 1 ), "translate minus one" );

eval { $codon->translate( $dna, -1 ); };
like( $@, qr{Wrong frame}i, "Wrong frame" );

done_testing();
