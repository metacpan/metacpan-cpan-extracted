use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load( 'corpus/test/legacy/group-brackets.changes' );

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, '', 'no preamble' );

my @releases = $changes->releases;

is( scalar @releases, 1, 'has 1 release' );
isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
is( $releases[ 0 ]->version, '0.01',       'version' );
is( $releases[ 0 ]->date,    '2010-06-16', 'date' );
is_deeply(
    $releases[ 0 ]->changes,
    { 'Group 1' => [
        'Initial release [not a group], seriously.',
        'change [also] [not a group]',
    ] },
    'full changes'
);
is_deeply( [ $releases[ 0 ]->groups ], [ 'Group 1' ], 'one group' );
is_deeply(
    $releases[ 0 ]->changes( 'Group 1' ),
    [
        'Initial release [not a group], seriously.',
        'change [also] [not a group]',
    ],
    'one change line'
);

done_testing;
