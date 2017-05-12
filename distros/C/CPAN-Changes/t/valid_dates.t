use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my @dates = (
    '2000',
    '2000-01',
    '2000-01-01',
    '2000-01-01T12:00',
    '2000-01-01T12:00Z',
    '2000-01-01T12:00+04:00',
    '2000-01-01T12:00+04:00:00',
    '2000-01-01 12:00', # optional "T"
);

for my $date ( @dates ) {
    ok( $date =~ m[^${CPAN::Changes::W3CDTF_REGEX}$], "Valid Date: $date" );
}

done_testing;
