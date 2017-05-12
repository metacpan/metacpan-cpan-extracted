#!perl

use Test::More 'no_plan';
use Bio::Translator::Utils;
use List::Compare;

my $utils = new Bio::Translator::Utils();

eval { $utils->regex() };
ok( $@, 'regex died with no parameters' );

eval { $utils->regex('') };
ok( $@, 'regex died with empty string' );

eval { $utils->regex('foo') };
ok( $@, 'regex died on invalid codon' );

eval { $utils->regex('F') };
ok( !$@, 'regex ran with just codon' );

foreach (1, -1) {
    eval { $utils->regex( 'F', { strand => $_ } ) };
    ok( !$@, "regex ran with strand = $_" );
}

eval { $utils->regex( 'F', { strand => 2 } ) };
ok( $@, 'regex died with strand = 2' );

my @codons = ( [qw(TTT TTC TTY)], [qw(AAA GAA RAA)] );

foreach my $strand ( 1, -1 ) {
    my $regex = $utils->regex( 'F', { strand => $strand } );
    my $codons = shift @codons;
    foreach my $codon (@$codons) {
        ok( $codon =~ m/$regex/, "Codon $codon matched" );
    }

    ok( 'ZZZ' !~ m/$regex/, 'Codon ZZZ did not match' );
}
