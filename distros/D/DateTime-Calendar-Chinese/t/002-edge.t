use strict;
use Test::More tests => 13;
use_ok("DateTime::Calendar::Chinese");

# XXX - going from a non-leap year to a leap-year was causing much
# unhappiness... we explicitly check for the boundary case where
# we go from one year to the other

# Note, make sure the year and the previous years are in the same cycle

my @data = (
    #  new year - 1 day
    DateTime->new(year => 2003, month => 1, day => 31, time_zone => 'UTC'),
    DateTime->new(year => 2004, month => 1, day => 20, time_zone => 'UTC')
);

foreach my $dt (@data) {
    my $cc_ny_eve = DateTime::Calendar::Chinese->from_object(object => $dt);
    my $cc_ny     = DateTime::Calendar::Chinese->from_object(
        object => $dt + DateTime::Duration->new(days => 1));

    is $cc_ny_eve->cycle, $cc_ny->cycle, 
        sprintf( "cycle is the same: %d = %d", $cc_ny_eve->cycle, $cc_ny->cycle );
    ok $cc_ny_eve->cycle_year + 1 == $cc_ny->cycle_year,
        sprintf( "cycle year is 1 yr apart: %d -> %d", $cc_ny_eve->cycle_year, $cc_ny->cycle_year );
    is($cc_ny_eve->month, 12,
        sprintf( "the eve must be 12th month: %d", $cc_ny_eve->month ) );
    like($cc_ny_eve->day, qr(^29|30),
        sprintf( "the eve must be either 29th or 30th day: %d", $cc_ny_eve->day) );

    is($cc_ny->month, 1,
        sprintf( "new years day must be 1st month: %d", $cc_ny->month ) );
    is($cc_ny->day, 1,
        sprintf( "new years day must be 1st day: %d", $cc_ny->day ) );
}

