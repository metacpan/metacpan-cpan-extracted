use strict;
use warnings;

use Test::More tests => 24;
BEGIN{
    use_ok('Class::Measure');
}

eval{ Class::Measure->new };
ok( $@, 'cannot create from base class' );

{ package MeasureTest; use base qw( Class::Measure ); }

eval{ MeasureTest->new };
ok( $@, 'invalid number of arguments' );

eval{ MeasureTest->new( 2, 'inches' ) };
ok( $@, 'unkown unit' );

MeasureTest->reg_units(
    qw( inch foot yard centimeter meter )
);
MeasureTest->reg_aliases(
    'inches' => 'inch',
    'feet' => 'foot',
    'yards' => 'yard',
    'centimeters' => 'centimeter',
    'meters' => 'meter',
);
MeasureTest->reg_convs(
    12, 'inches' => 'foot',
    3, 'feet' => 'yard',
    'yard' => 91.44, 'centimeters',
    100, 'centimeters' => 'meter',
);

my $path = MeasureTest->_path( 'inch' => 'meter' );
ok( (@$path==5), 'long path correct' );

MeasureTest->reg_convs( 'yard' => .9144, 'meter' );
$path = MeasureTest->_path( 'inch' => 'meter' );
ok( (@$path==4), 'shortened path' );

$path = MeasureTest->_path( 'foot' => 'inch' );
ok( (@$path==2), 'one step path' );

my $m = MeasureTest->new( 3, 'inch' );

$m += 2;
ok( ($m->value==5), 'obj += num' );
$m ++;
ok( ($m->value==6), 'obj ++' );
$m = 2 + $m;
ok( ($m->value==8), 'obj = num + obj' );
$m = $m + MeasureTest->new( 1, 'foot');
ok( ($m->value==20), 'obj = obj + obj' );

$m -= 2;
ok( ($m->value==18), 'obj -= num' );
$m --;
ok( ($m->value==17), 'obj --' );
$m = 30 - $m;
ok( ($m->value==13), 'obj = num - obj' );
$m = $m - MeasureTest->new( 1, 'foot' );
ok( ($m->value==1), 'obj = obj - obj' );

$m->set_value( 2, 'foot' );
$m *= 2;
ok( ($m->value==4), 'obj *= num' );
$m = 3 * MeasureTest->new( 2, 'inch' );
ok( ($m->value==6), 'obj = num * obj' );
$m = MeasureTest->new( 3, 'inch' ) * 3;
ok( ($m->value==9), 'obj = obj * num' );

$m->set_value( 10, 'foot' );
$m /= 2;
ok( ($m->value==5), 'obj /= num' );
$m = 10 / MeasureTest->new( 5, 'inch' );
ok( ($m->value==2), 'obj = num / obj' );
$m = MeasureTest->new( 6, 'inch' ) / 2;
ok( ($m->value==3), 'obj = obj / num' );

$m->set_value( 1, 'foot' );
ok( ($m->inches==12), 'autoloaded conversion (inches)' );
ok( (int($m->yards*10)==3), 'autoloaded conversion (yards)' );

eval{ return "$m" };
ok( !$@, 'stringified' );

