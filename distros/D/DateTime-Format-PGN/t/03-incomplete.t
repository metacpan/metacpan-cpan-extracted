#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 7;

require_ok( 'DateTime::Format::PGN' );

my $string = '2004.04.23';
my $dtf = DateTime::Format::PGN->new({use_incomplete => 1});
my $dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt),$string, $string);

$string = '1812.12.09';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);

$string = '????.??.??';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);

$string = '????.07.31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);

$string = '1943.??.??';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);

$string = '1485.??.24';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), $string, $string);