
use Test::More tests => 7;

use warnings;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;


$strf = DateTime::Format::Duration->new(
    base => DateTime->new(year=>2003),
    pattern => '%V weeks, %u days',
);
$duration = DateTime::Duration->new( days => 17 );
is( $strf->format_duration( $duration ), '2 weeks, 3 days', '17 days = 2 weeks, 3 days' );




$strf = DateTime::Format::Duration->new(
    pattern => '%N %6N %3N',
);
$duration = DateTime::Duration->new( days => 17, nanoseconds => 654321987 );
is( $strf->format_duration( $duration ), '654321987 654321 654', 'Nanosecond precision' );




$strf = DateTime::Format::Duration->new(
    pattern => '%V',
    base    => DateTime->new( year => 2003 ),
);
$duration = DateTime::Duration->new( days => 22, hours => 36 );
is( $strf->format_duration( $duration ), '3', '22 days, 36 hours as integer weeks' );

$strf->set_pattern('%W');
is( $strf->format_duration( $duration ), '3.357142857', '22 days, 36 hours as floating weeks' );

$strf->set_pattern('%j');
is( $strf->format_duration( $duration ), '23', '22 days, 36 hours as days' );

$strf->set_pattern('%s');
is( $strf->format_duration( $duration ), (22*24*60*60) + (36*60*60), '22 days, 36 hours as seconds' );

$strf->set_pattern('%u');
is( $strf->format_duration( $duration ), '2', '22 days, 36 hours as days modulus 7' );

