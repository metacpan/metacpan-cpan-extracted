use strict;
use warnings;

use Test::More;
use Data::XLSX::Parser::Sheet;
use Data::Dumper;
my $dt =  Data::XLSX::Parser::Sheet::_convert_serial_time(0,41935.171365740738);
is( $dt->datetime(),'2014-10-23T04:06:46' , "datetime pos below");

$dt =  Data::XLSX::Parser::Sheet::_convert_serial_time(0,41935.171365740750);
is( $dt->datetime(),'2014-10-23T04:06:46' , "datetime pos above");

#$dt =  Data::XLSX::Parser::Sheet::_convert_serial_time(0,61.171365740738);
$dt =  Data::XLSX::Parser::Sheet::_convert_serial_time(0,61.171365740700);
is( $dt->datetime(),'1900-03-01T04:06:46' , "datetime neg below");

#$dt =  Data::XLSX::Parser::Sheet::_convert_serial_time(0,61.171365740750);
$dt =  Data::XLSX::Parser::Sheet::_convert_serial_time(0,61.17136574090);
is( $dt->datetime(),'1900-03-01T04:06:46' , "datetime neg above");

done_testing;
