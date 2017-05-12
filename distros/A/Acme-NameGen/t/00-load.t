#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 13;

BEGIN {
    use_ok('Acme::NameGen')                    || print "Bail out!\n";
    require_ok('Acme::NameGen')                || print "Bail out!\n";
    use_ok('Acme::NameGen::CPAN::Authors')     || print "Bail out!\n";
    require_ok('Acme::NameGen::CPAN::Authors') || print "Bail out!\n";
}

is( Acme::NameGen::CPAN::Authors::gen( 2, 8291 ), 'affectionate_MZIESCHA', 'Standard gen.' );
is( Acme::NameGen::CPAN::Authors::gen_lc( 2, 8291 ), 'affectionate_mziescha', 'Lowercase gen.' );
is( Acme::NameGen::CPAN::Authors::gen_uc( 2, 8291 ), 'AFFECTIONATE_MZIESCHA', 'Uppercase gen.' );
is( Acme::NameGen::CPAN::Authors::gen_uc( 4, 1885 ), 'AMAZING_CHANG-LIU', 'Standard with - gen.' );
is( Acme::NameGen::CPAN::Authors::gen_lc( 4, 1885 ), 'amazing_chang-liu', 'Lowercase with - gen.' );
is( Acme::NameGen::CPAN::Authors::gen_uc( 4, 1885 ), 'AMAZING_CHANG-LIU', 'Uppercase with - gen.' );

is( Acme::NameGen::gen( 2, [ 'spoon', 'knife', 'fork' ], 1 ),
    'affectionate_knife', 'Standard gen.' );
is( Acme::NameGen::gen_lc( 2, [ 'spoon', 'knife', 'fork' ], 1 ),
    'affectionate_knife', 'Lowercase gen.' );
is( Acme::NameGen::gen_uc( 2, [ 'spoon', 'knife', 'fork' ], 1 ),
    'AFFECTIONATE_KNIFE', 'Uppercase gen.' );

diag("Testing Acme::NameGen::CPAN::Authors $Acme::NameGen::VERSION, Perl $], $^X");
