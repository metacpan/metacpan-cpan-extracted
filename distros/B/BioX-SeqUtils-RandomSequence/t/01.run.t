use Test::More tests => 7;

BEGIN {
use_ok( 'BioX::SeqUtils::RandomSequence' );
}

my $randomizer = BioX::SeqUtils::RandomSequence->new();
my $test = $randomizer->rand_dna(), "\n";
ok( $test, "random dinucleotide");

my $test = $randomizer->rand_dna({ l => 200 }), "\n";
ok( $test, "random dna");

my $test = $randomizer->rand_rna(), "\n";
ok( $test, "random rna");

my $test = $randomizer->rand_pro(), "\n";
ok( $test, "random protein");

my $test = $randomizer->rand_pro_set(), "\n";
ok( $test, "random protein set (scalar)");

my ($test, $dummy) = $randomizer->rand_pro_set(), "\n";
ok( $test, "random protein set (list)");

diag( "Testing BioX::SeqUtils::RandomSequence $BioX::SeqUtils::RandomSequence::VERSION" );
