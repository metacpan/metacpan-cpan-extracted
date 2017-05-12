#!perl

use Test::More 'no_plan';
use Bio::Translator::Utils;
use List::Compare;

my $utils = new Bio::Translator::Utils();

eval { $utils->find() };
ok( $@, 'find died with no options' );

eval { $utils->find( \'TTTTTCTTY' ) };
ok( $@, 'find died with just seq_ref' );

eval { $utils->find( \'TTTTTCTTY', '' ) };
ok( $@, 'find died with just seq_ref and empty string for residue' );

eval { $utils->find( \'TTTTTCTTY', 'foo' ) };
ok( $@, 'find died with just seq_ref and invalid residue' );

foreach ( 1, -1 ) {
    eval { $utils->find( \'TTTTTCTTY', 'F', { strand => $_ } ) };
    ok( !$@, "find ran with strand = $_" );
}

eval { $utils->regex( \'TTTTTCTTY', 'F', { strand => 2 } ) };
ok( $@, 'find died with strand = 2' );

my @strings = qw(TTTTTCTTY AAAGAARAA);
my @expected = ([ 0, 1, 2, 3, 6 ], [ 0, 3, 6 ]);

foreach my $strand (1, -1) {
    my $string = shift @strings;
    my $expected = shift @expected;
    
    my $indices = $utils->find( \$string, 'F', { strand => $strand } );
    
    is (scalar(@$indices), scalar(@$expected), 'Expected number of indices');
    
    my $lc = List::Compare->new( $expected, $indices );
    is( scalar( $lc->get_symdiff ), 0, '0 differences between lists' );
}