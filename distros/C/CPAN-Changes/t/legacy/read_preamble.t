use strict;
use warnings;

use Test::More;

use CPAN::Changes;

{
    my $changes = CPAN::Changes->load( 'corpus/test/legacy/preamble.changes' );

    isa_ok( $changes, 'CPAN::Changes' );
    is( $changes->preamble, 'Revision history for perl module Foo::Bar',
        'preamble' );

    check_releases( $changes );
}

{
    my $changes = CPAN::Changes->load( 'corpus/test/legacy/long_preamble.changes' );

    isa_ok( $changes, 'CPAN::Changes' );
    is( $changes->preamble, 'Revision history for perl module Foo::Bar

Yep.',
        'preamble' );

    check_releases( $changes );
}

sub check_releases {
    my $changes  = shift;
    my @releases = $changes->releases;

    is( scalar @releases, 1, 'has 1 release' );
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
}

done_testing;
