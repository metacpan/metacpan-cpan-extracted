use strict;
use warnings;
use Test::More tests => 15;
use DateTime;

BEGIN { use DateTime::Util::DayOfWeek; }
my $dt = DateTime->new( year => 2006, month => 1, day => 18 );

ok( !$dt->is_monday,   $dt->strftime('%Y-%m-%d(%a)') . ' is not monday' );
ok( !$dt->is_tuesday,  $dt->strftime('%Y-%m-%d(%a)') . ' is not tuesday' );
ok( $dt->is_wednesday, $dt->strftime('%Y-%m-%d(%a)') . ' is wednesday' );
ok( !$dt->is_thursday, $dt->strftime('%Y-%m-%d(%a)') . ' is not thursday' );
ok( !$dt->is_friday,   $dt->strftime('%Y-%m-%d(%a)') . ' is not friday' );
ok( !$dt->is_saturday, $dt->strftime('%Y-%m-%d(%a)') . ' is not saturday' );
ok( !$dt->is_sunday,   $dt->strftime('%Y-%m-%d(%a)') . ' is not sunday' );

$dt->add( days => 1 );
ok( !$dt->is_wednesday, $dt->strftime('%Y-%m-%d(%a)') . ' is not wednesday' );

$dt = DateTime->new( year => 2007, month => 2, day => 5 );
ok( $dt->is_monday, $dt->strftime('%Y-%m-%d(%a)') . ' is monday' );
$dt->add( days => 1 );
ok( $dt->is_tuesday, $dt->strftime('%Y-%m-%d(%a)') . ' is tuesday' );
$dt->add( days => 1 );
ok( $dt->is_wednesday, $dt->strftime('%Y-%m-%d(%a)') . ' is wednesday' );
$dt->add( days => 1 );
ok( $dt->is_thursday, $dt->strftime('%Y-%m-%d(%a)') . ' is thursday' );
$dt->add( days => 1 );
ok( $dt->is_friday, $dt->strftime('%Y-%m-%d(%a)') . ' is friday' );
$dt->add( days => 1 );
ok( $dt->is_saturday, $dt->strftime('%Y-%m-%d(%a)') . ' is saturday' );
$dt->add( days => 1 );
ok( $dt->is_sunday, $dt->strftime('%Y-%m-%d(%a)') . ' is sunday' );
