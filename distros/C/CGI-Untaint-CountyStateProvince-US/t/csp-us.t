#!perl -wT

use Test::More tests => 8;
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
};

my $untainter = CGI::Untaint->new($vars);
my $c = $untainter->extract(-as_CountyStateProvince => 'state1');
ok($c eq 'PA', 'PA');

$c = $untainter->extract(-as_CountyStateProvince => 'state2');
ok($c eq 'WV', 'West Virginia');

$c = $untainter->extract(-as_CountyStateProvince => 'state3');
ok(!defined($c), 'South Yorkshire');

$c = $untainter->extract(-as_CountyStateProvince => 'state4');
ok(!defined($c), 'Empty');

$c = $untainter->extract(-as_CountyStateProvince => 'state5');
ok(!defined($c), '*&^');

$c = $untainter->extract(-as_CountyStateProvince => 'state6');
ok($c eq 'MA', 'Ma');
