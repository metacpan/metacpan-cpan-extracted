#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 16;

require_ok( 'DateTime::Format::PGN' );

my $string = '2004-01-31';
my $dtf = DateTime::Format::PGN->new(fix_errors => 1, use_incomplete => 1);
my $dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt),'2004.01.31', $string);

$string = '2004-02-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.??.??', $string);

$string = '2004-03-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.03.31', $string);

$string = '2004-04-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.??.??', $string);

$string = '2004-05-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.05.31', $string);

$string = '2004-06-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.??.??', $string);

$string = '2004-07-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.07.31', $string);

$string = '2004-8-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.08.31', $string);

$string = '2004-9-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.??.??', $string);

$string = '2004-10-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.10.31', $string);

$string = '2004-11-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.??.??', $string);

$string = '2004-12-31';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.12.31', $string);

$string = '2003.2.29';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2003.??.??', $string);

$string = '2000.2.29';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2000.??.??', $string);

$string = '2004.2.29';
$dt = $dtf->parse_datetime($string);
is($dtf->format_datetime($dt), '2004.02.29', $string);