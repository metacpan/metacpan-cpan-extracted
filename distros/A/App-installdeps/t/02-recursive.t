use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/target2";
use Getopt::Config::FromPod;
Getopt::Config::FromPod->set_class_default(-file => 'bin/installdeps');


my @tests = (
	['-u',   ['target2/1.pl'], [qw(App::installdeps::Dummy)], '-u'],
	['-R',   ['target2/1.pl'], [qw(App::installdeps::Dummy2 App::installdeps::Dummy3)], '-R'],
	['-Ru',  ['target2/1.pl'], [qw(App::installdeps::Dummy App::installdeps::Dummy2 App::installdeps::Dummy3)], '-Ru'],
	['-ur',  ['target2/1.pl'], [qw(App::installdeps::Dummy)], '-ur'],
	['-Rr',  ['target2/1.pl'], [qw(App::installdeps::Dummy2)], '-Rr'],
	['-Rru', ['target2/1.pl'], [qw(App::installdeps::Dummy App::installdeps::Dummy2)], '-Rru'],
);

plan tests => 1 + 2 * @tests;

use_ok 'App::installdeps';

foreach my $test (@tests) {
	my ($opts, $target);
	lives_ok { ($opts, $target) = App::installdeps::_process(ref $test->[0] ? @{$test->[0]} : $test->[0], map { "$FindBin::Bin/$_" } @{$test->[1]}) };
	is_deeply([sort @$target], [sort @{$test->[2]}], $test->[3]);
}
