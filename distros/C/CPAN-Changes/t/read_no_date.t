use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load_string(<<'END_CHANGES');
1.01 Note
    - Second

1.00
    - First
END_CHANGES

isa_ok( $changes, 'CPAN::Changes' );

my @releases = $changes->releases;
is( scalar @releases, 2, 'has 2 releases' );

my @expected = (
    { date => undef, note => undef },
    { date => undef, note => 'Note' },
);

for ( 0..@expected - 1 ) {
    isa_ok( $releases[ $_ ], 'CPAN::Changes::Release' );
    is( $releases[ $_ ]->date, $expected[ $_ ]->{ date }, 'date' );
    is( $releases[ $_ ]->note, $expected[ $_ ]->{ note }, 'note' );
}

done_testing;
