#!perl -wT

use strict;
use warnings;
use diagnostics;
use Test::NoWarnings;

use Test::More tests => 12;
BEGIN {
	use_ok('CGI::Untaint');
	use_ok('CGI::Untaint::CountyStateProvince::GB');
};

my $vars = {
    state1 => 'MD',
    state2 => 'Kent',
    state3 => ' ',
    state4 => 'West Yorkshire',
    state5 => 'West Yorks',
    state6 => 'Northants',
    state7 => '*&^',
    state8 => 'durham',
    state9 => 'cleveland',
};

my $untainter = CGI::Untaint->new($vars);
my $c = $untainter->extract(-as_CountyStateProvince => 'state1');
ok(!defined($c), 'Maryland');

$c = $untainter->extract(-as_CountyStateProvince => 'state2');
ok($c eq 'kent', 'Kent');

$c = $untainter->extract(-as_CountyStateProvince => 'state3');
ok(!defined($c), 'Empty');

$c = $untainter->extract(-as_CountyStateProvince => 'state4');
ok($c eq 'west yorkshire', 'West Yorkshire');

$c = $untainter->extract(-as_CountyStateProvince => 'state5');
ok($c eq 'west yorkshire', 'West Yorks');

$c = $untainter->extract(-as_CountyStateProvince => 'state6');
ok($c eq 'northamptonshire', 'Northants');

$c = $untainter->extract(-as_CountyStateProvince => 'state7');
ok(!defined($c), '*&^');

$c = $untainter->extract(-as_CountyStateProvince => 'state8');
ok($c eq 'county durham', 'Durham');

$c = $untainter->extract(-as_CountyStateProvince => 'state9');
ok($c eq 'teesside', 'Cleveland');
