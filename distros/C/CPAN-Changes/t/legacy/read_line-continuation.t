use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load( 'corpus/test/legacy/line-continuation.changes' );

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, '', 'no preamble' );

my @releases = $changes->releases;

is( scalar @releases, 1, 'has 1 release' );
isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
is( $releases[ 0 ]->version, '0.01',       'version' );
is( $releases[ 0 ]->date,    '2010-06-16', 'date' );
is_deeply(
    $releases[ 0 ]->changes,
    { '' => [ "Initial release This line is part of the first" ] },
    'full changes'
);
is_deeply( [ $releases[ 0 ]->groups ], [ '' ], 'only the main group' );
is_deeply(
    $releases[ 0 ]->changes( '' ),
    [ "Initial release This line is part of the first" ],
    'one change line'
);

done_testing;
