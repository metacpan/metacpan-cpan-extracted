#!perl -wT

use strict;
use warnings;
use diagnostics;
use Test::NoWarnings;

use Test::More tests => 13;
BEGIN {
	use_ok('CGI::Untaint');
	use_ok('CGI::Untaint::CountyStateProvince::US');
};

my $vars = {
    state1 => 'PA',
    state2 => 'West Virginia',
    state3 => 'South Yorkshire',
    state4 => ' ',
    state5 => '*&^',
    state6 => 'Ma',
    state7 => 'ZZ',
};

my $untainter = CGI::Untaint->new($vars);
my $c = $untainter->extract(-as_CountyStateProvince => 'state1');
ok(defined($c));
ok($c eq 'PA', 'PA');

$c = $untainter->extract(-as_CountyStateProvince => 'state2');
ok(defined($c));
ok($c eq 'WV', 'West Virginia');

$c = $untainter->extract(-as_CountyStateProvince => 'state3');
ok(!defined($c), 'South Yorkshire');

$c = $untainter->extract(-as_CountyStateProvince => 'state4');
ok(!defined($c), 'Empty');

$c = $untainter->extract(-as_CountyStateProvince => 'state5');
ok(!defined($c), '*&^');

$c = $untainter->extract(-as_CountyStateProvince => 'state6');
ok(defined($c));
ok($c eq 'MA', 'Ma');

$c = $untainter->extract(-as_CountyStateProvince => 'state7');
ok(!defined($c), 'ZZ');

