use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load( 'corpus/test/legacy/dist-zilla_format.changes' );

isa_ok( $changes, 'CPAN::Changes' );

my @releases = $changes->releases;
is( scalar @releases, 1, 'has 1 release' );

isa_ok( $releases[ 0 ], 'CPAN::Changes::Release' );
is( $releases[ 0 ]->date, '2010-12-28T00:15:12Z', 'date' );

done_testing;
