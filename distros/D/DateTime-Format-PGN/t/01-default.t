#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

require_ok( 'DateTime::Format::PGN' );

my $string = '2004.04.23';
my $dtf = DateTime::Format::PGN->new();
my $dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt),$string, $string);

$string = '1812.12.09';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);

$string = '????.??.??';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '0001.01.01', $string);

$string = '????.07.31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '0001.07.31', $string);

$string = '1943.??.??';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1943.01.01', $string);

$string = '1485.??.24';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1485.01.24', $string);

$string = '0000.05.23';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '0001.01.01', $string);