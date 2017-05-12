#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

use DateTime;
use DateTime::Event::ICal;
use Acme::PM::Barcelona::Meeting;

{
    my $barcelona_pm = Acme::PM::Barcelona::Meeting->new();
    isa_ok( $barcelona_pm, 'Acme::PM::Barcelona::Meeting' );

    # every last Thu of the month at 20:00:00
    my $dt_set = DateTime::Event::ICal->recur(
        dtstart  => DateTime->now(),
        freq     => 'monthly',
        byday    => [ '-1th' ],
        byhour   => [ 20 ],
        byminute => [ 0 ],
        bysecond => [ 0 ],
    );

    is_deeply( $barcelona_pm, $dt_set, "next meeting verified" );
}
