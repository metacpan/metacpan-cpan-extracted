use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load( 'corpus/test/legacy/version-date-separator.changes' );

isa_ok( $changes, 'CPAN::Changes' );
is( $changes->preamble, '', 'no preamble' );

my @releases = $changes->releases;

is( scalar @releases, 3, 'has 3 releases' );
is( $releases[ 2 ]->version, '0.03',       'version' );
is( $releases[ 2 ]->date,    '2013-12-11', 'date' );
is( $releases[ 1 ]->version, '0.02',       'version' );
is( $releases[ 1 ]->date,    '2013-12-10', 'date' );
is( $releases[ 0 ]->version, '0.01',       'version' );
is( $releases[ 0 ]->date,    '2013-12-09', 'date' );

done_testing;
