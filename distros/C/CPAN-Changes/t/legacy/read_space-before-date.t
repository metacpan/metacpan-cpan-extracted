use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load( 'corpus/test/legacy/space-before-date.changes' );

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, '', 'no preamble' );

my @releases = $changes->releases;

is( scalar @releases, 2, 'has 2 release' );

isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
is( $releases[ 0 ]->version, '0.01',       'version' );
is( $releases[ 0 ]->date,    '2010-06-16', 'date' );
is_deeply(
    $releases[ 0 ]->changes,
    { '' => [ 'Initial release' ] },
    'full changes'
);
is_deeply( [ $releases[ 0 ]->groups ], [ '' ], 'only the main group' );
is_deeply(
    $releases[ 0 ]->changes( '' ),
    [ 'Initial release' ],
    'one change line'
);

isa_ok( $releases[ 1 ], 'CPAN::Changes::Release' );
is( $releases[ 1 ]->version, '0.02',       'version' );
is( $releases[ 1 ]->date,    '2010-06-17', 'date' );
is_deeply(
    $releases[ 1 ]->changes,
    { '' => [ 'Testing tabs' ] },
    'full changes'
);
is_deeply( [ $releases[ 1 ]->groups ], [ '' ], 'only the main group' );
is_deeply(
    $releases[ 1 ]->changes( '' ),
    [ 'Testing tabs' ],
    'one change line'
);

done_testing;
