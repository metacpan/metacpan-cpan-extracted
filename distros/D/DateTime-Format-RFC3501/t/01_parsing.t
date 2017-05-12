#!perl

use strict;
use warnings;

use Test::More;

use DateTime                  qw( );
use DateTime::Format::RFC3501 qw( );

my @tests = (
    [
        ' 1-Jul-2002 13:50:05 +0000',
        DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'UTC' ),
    ],
    [
        ' 1-Jul-2002 13:50:05 +0200',
        DateTime->new( year => 2002, month => 7, day => 1, hour => 13, minute => 50, second => 5, time_zone => 'Europe/Andorra' ),
    ],
);

plan tests => 3 * @tests ;

for (@tests) {
    my ( $str, $expected_dt ) = @$_;

    my $actual_dt = DateTime::Format::RFC3501->parse_datetime($str);
    isa_ok( $actual_dt, 'DateTime' );

    is( $actual_dt, $str, 'RFC3501 formatter' );

    $actual_dt->set_formatter(undef);
    is( $actual_dt, $expected_dt, 'default DateTime formatter' );
}
