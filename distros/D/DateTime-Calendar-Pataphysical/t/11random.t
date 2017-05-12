use strict;
use warnings;
use Test::More;
use DateTime;
use DateTime::Calendar::Pataphysical;

my @class = qw( DateTime DateTime::Calendar::Pataphysical );

my $tests = shift || 100;
plan tests => 2 * $tests;

for ( 1 .. $tests ) {
    my $epoch = 2**31 - int( rand( 2**32 ) );
    for ( 1 .. 2 ) {

        # round trip one class through the other
        my $dt = $class[0]->from_epoch( epoch => $epoch );
        my $orig = $dt->clone;

        $dt = $class[1]->from_object( object => $dt );

        my $dt_again = $class[0]->from_object( object => $dt );

        local $" = ' <=> ';
        ok( $orig == $dt_again,
            sprintf "%-10s round-trip %s <-> %s",
            $orig->ymd, @class
        );

        # next time do it in revese
        @class = reverse @class;
    }
}

