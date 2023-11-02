use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load( 'corpus/test/legacy/dist-zilla.changes',
    next_token => qr/\{\{\$NEXT\}\}/);

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, 'Revision history for Catalyst-Plugin-Sitemap',
    'preamble' );

my @releases = $changes->releases;

is( scalar @releases, 3, 'has 3 releases' );

my $r = pop @releases;

isa_ok( $r, 'CPAN::Changes::Release' );
is( $r->version, '{{$NEXT}}',       'version' );
is( $r->date,    undef, 'date' );
is_deeply(
    $r->changes,
    { '' => [ 'Something' ] },
    'full changes'
);
is_deeply( [ $r->groups ], [ '' ], 'only the main group' );

isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
is( $releases[ 0 ]->version, '0.0.1',      'version' );
is( $releases[ 0 ]->date,    '2010-09-29', 'date' );
is_deeply(
    $releases[ 0 ]->changes,
    { '' => [ 'original version unleashed on an unsuspecting world' ] },
    'full changes'
);
is_deeply( [ $releases[ 0 ]->groups ], [ '' ], 'only the main group' );

isa_ok( $releases[ 1 ], 'CPAN::Changes::Release' );
is( $releases[ 1 ]->version, '1.0.0',      'version' );
is( $releases[ 1 ]->date,    '2010-11-30', 'date' );

done_testing;
