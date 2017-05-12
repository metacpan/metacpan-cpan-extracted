use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;
use Apache::SWIT::Test::Utils;
use Cwd qw(abs_path getcwd);
use File::Path qw(rmtree);
use File::Slurp;

BEGIN { use_ok('Apache::SWIT::Test::ModuleTester'); }

my $mt = Apache::SWIT::Test::ModuleTester->new({ root_class => 'TTT', no_cleanup => 1 });
chdir $mt->root_dir;
`cp -a . ../foo`;
$mt->make_swit_project;
ok(-f 'LICENSE');
ok(-f 'lib/TTT/DB/Schema.pm');

`cp -a . ../foo`;
is($?, 0) or ASTU_Wait;

`perl Makefile.PL`;
is($?, 0) or ASTU_Wait;

my $d1 = abs_path(getcwd());

chdir('../foo');
`perl Makefile.PL`;
is($?, 0) or ASTU_Wait;

my $d2 = abs_path(getcwd());

chdir('/');

sub fork_apache {
	my $dir = shift;
	my $pid = fork();
	return $pid if $pid;
	chdir($dir);
	my $res = `make test_apache 2>&1`;
	chdir('/');
	write_file("$dir/err", $res) if $?;
	exit $?;
}

my $pid1 = fork_apache($d1);
sleep 1;
my $pid2 = fork_apache($d2);
waitpid($pid1, 0);
is($?, 0);
waitpid($pid2, 0);
is($?, 0);

is(-f "$d1/err", undef) or ASTU_Wait(scalar read_file("$d1/err"));
is(-f "$d2/err", undef) or ASTU_Wait(scalar read_file("$d2/err"));
rmtree($mt->root_dir);
