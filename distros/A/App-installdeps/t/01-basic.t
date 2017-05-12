use Test::More;
use Test::Exception;
use FindBin;
use Getopt::Config::FromPod;
Getopt::Config::FromPod->set_class_default(-file => 'bin/installdeps');


my @tests = (
	['-n',   ['target/1.pl'], [], 'simple -n'],
	['-nX',  ['target/1.pl'], ['$_'], 'simple -nX'],
	['-nu',  ['target/1.pl'], [qw(Test::More App::installdeps)], 'simple -nu'],
	['-nru', ['target/1.pl'], [qw(Test::More App::installdeps)], 'simple -nru'],
	['-n',   ['target/2.pl'], [], 'eval -n'],
	['-nu',  ['target/2.pl'], [qw(Test::More Test::Exception)], 'eval -nu'],
	['-nru', ['target/2.pl'], [qw(Test::More)], 'eval -nru'],
	['-n',   [qw(target/1.pl target/2.pl)], [], 'multi -n'],
	['-nu',  [qw(target/1.pl target/2.pl)], [qw(Test::More Test::Exception App::installdeps)], 'multi -nu'],
	['-nru', [qw(target/1.pl target/2.pl)], [qw(Test::More App::installdeps)], 'multi -nru'],
	['-n',   ['target'], [], 'dir -n'],
	['-nu',  ['target'], [qw(Test::More Test::Exception App::installdeps)], 'dir -nu'],
	['-nru', ['target'], [qw(Test::More App::installdeps)], 'dir -nru'],
	[['-n', '-x', '^Test::'],   ['target'], [], 'dir -nx'],
	[['-nu', '-x', '^Test::'],  ['target'], [qw(App::installdeps)], 'dir -nux'],
	[['-nru', '-x', '^Test::'], ['target'], [qw(App::installdeps)], 'dir -nrux'],
);

plan tests => 1 + 2 * 2 + 2 * @tests;

use_ok 'App::installdeps';

{
	my ($opts, $target);
	lives_ok { ($opts, $target) = App::installdeps::_process('-n', "$FindBin::Bin/target/1.pl") };
	is($opts->{i}, 'cpanm', 'default command');
	lives_ok { ($opts, $target) = App::installdeps::_process('-n', '-i', 'cpan', "$FindBin::Bin/target/1.pl") };
	is($opts->{i}, 'cpan', 'overridden command');
}

foreach my $test (@tests) {
	my ($opts, $target);
	lives_ok { ($opts, $target) = App::installdeps::_process(ref $test->[0] ? @{$test->[0]} : $test->[0], map { "$FindBin::Bin/$_" } @{$test->[1]}) };
	is_deeply([sort @$target], [sort @{$test->[2]}], $test->[3]);
}
