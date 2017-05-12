#!perl

use Test::More 'no_plan';
use Bio::Translator::Utils;
use List::Compare;

my $utils = new Bio::Translator::Utils();

eval { $utils->codons() };
ok( $@, 'codons died with no parameters' );

eval { $utils->codons('') };
ok( $@, 'codons died with empty string' );

eval { $utils->codons('foo') };
ok( $@, 'codons died on invalid codon' );

eval { $utils->codons('F') };
ok( !$@, 'codons ran with just codon' );

eval { $utils->codons( 'F', { strand => 1 } ) };
ok( !$@, 'codons ran with strand = 1' );

eval { $utils->codons( 'F', { strand => -1 } ) };
ok( !$@, 'codons ran with strand = -1' );
eval { $utils->codons( 'F', { strand => 2 } ) };
ok( $@, 'codons died with strand = 2' );

my @entries = (
    [ 'F' => [ [qw(TTT TTC TTY)], [qw(AAA GAA RAA)] ] ],
    [
        'start' => [
            [qw(YTG WTG MTG HTG TTG CTG ATG)],
            [qw(CAR CAW CAK CAD CAA CAG CAT)]
        ]
    ]
);

foreach my $entry (@entries) {
    my ( $residue, $expecteds ) = @$entry;

    foreach my $strand ( 1, -1 ) {
        my $codons = $utils->codons( $residue, { strand => $strand } );
        my $expected = shift @$expecteds;
        is( scalar(@$codons), scalar(@$expected),
            "Got expected number of codons for $residue" );

        my $lc = List::Compare->new( $expected, $codons );

        is( scalar( $lc->get_symdiff ), 0,
            '0 differences between codon lists' );
    }
}
