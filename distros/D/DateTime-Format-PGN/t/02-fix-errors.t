#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 12;

require_ok( 'DateTime::Format::PGN' );

my $string = '2004.04.23';
my $dtf = DateTime::Format::PGN->new({fix_errors => 1});
my $dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt),$string, $string);

$string = '1812.12.09';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);

$string = 'June 3rd, 1987';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1987.06.03', $string);

$string = '1865.31.12';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1865.12.31', $string);

$string = '7.12.1943';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1943.01.01', $string);

$string = '1867-6-14';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1867.06.14', $string);

$string = '2001.xx.29';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2001.01.01', $string);

$string = '17.12.1943';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1943.12.17', $string);

$string = '2007.00.13';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2007.01.01', $string);

$string = '2016.05.00';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2016.01.01', $string);

$dtf = DateTime::Format::PGN->new({fix_errors => 1, use_incomplete => 1});
$string = '4.3.1943';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '1943.??.??', $string);
