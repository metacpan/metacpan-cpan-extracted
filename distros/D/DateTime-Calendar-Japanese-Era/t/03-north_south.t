use strict;
use Test::More (tests => 3);

BEGIN
{
    use_ok("DateTime::Calendar::Japanese::Era", "SOUTH_REGIME", "NORTH_REGIME");
}
my $dt = DateTime->new(year => 1335);

my $e_south = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => $dt,
    regime   => SOUTH_REGIME
);
my $e_north = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => $dt,
    regime   => NORTH_REGIME
);

is($e_south->id, 'S_KENMU');
is($e_north->id, 'SHOUKEI');


