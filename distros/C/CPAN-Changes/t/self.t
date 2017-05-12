use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes  = CPAN::Changes->load( 'Changes' );
my @releases = $changes->releases;

isa_ok( $changes, 'CPAN::Changes' );
ok( scalar @releases, 'has releases' );
isa_ok( $_, 'CPAN::Changes::Release' ) for @releases;

done_testing;
