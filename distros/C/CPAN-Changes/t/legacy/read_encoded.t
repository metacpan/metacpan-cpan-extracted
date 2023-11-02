use strict;
use warnings;

use Test::More;

use CPAN::Changes;

for my $file ( 'corpus/test/legacy/utf8.changes', 'corpus/test/legacy/latin1.changes' ) {
    my $changes = CPAN::Changes->load( $file );

    isa_ok( $changes, 'CPAN::Changes' );
    is( $changes->preamble, '', 'no preamble' );

    my @releases = $changes->releases;

    is( scalar @releases, 1, 'has 1 release' );
    isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
    is( $releases[ 0 ]->version, '0.01',       'version' );
    is( $releases[ 0 ]->date,    '2010-06-16', 'date' );
    is_deeply(
        $releases[ 0 ]->changes,
        { '' => [ "change made by k\x{00E4}the" ] },
        'full changes'
    );
    is_deeply( [ $releases[ 0 ]->groups ], [ '' ], 'only the main group' );
    is_deeply(
        $releases[ 0 ]->changes( '' ),
        [ "change made by k\x{00E4}the" ],
        'one change line'
    );
}

done_testing;
