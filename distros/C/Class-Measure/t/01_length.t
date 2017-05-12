use strict;
use warnings;

use Test::More tests => 5;
BEGIN{
    use_ok('Class::Measure::Length', 'length');
}

my @units = sort Class::Measure::Length->units;
my $first = shift(@units);
my $m = length( 10, $first );
foreach my $unit (@units){
    $m->set_unit($unit);
}
$m->set_unit($first);
ok( ( int($m->$first) == 10 ), 'run all conversions' );

my $foot = length( 12, 'inches' );
is( $foot->feet(), 1, '12 inches is 1 foot' );
my $yard = $foot * 3;
is( $yard->yards(), 1, '3 feet is 1 yard' );
is( $yard->inches(), 36, '1 yard is 36 inches' );

