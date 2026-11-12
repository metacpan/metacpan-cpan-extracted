#!perl -w

use strict;
use warnings;
use Test::Most tests => 16;
use Test::NoWarnings;

BEGIN {
	require_ok('CGI::Info');
}

PATHS: {
	delete $ENV{'LOGDIR'};

	my $i = new_ok('CGI::Info');
	my $dir = $i->logdir();
	ok(defined($dir));
	diag($dir);
	ok(-w $dir);
	ok(-d $dir);

	ok($i->logdir('.') eq '.');
	ok($i->logdir() eq '.');

	$dir = CGI::Info::logdir();
	ok(defined($dir));
	diag($dir);
	ok(-w $dir);
	ok(-d $dir);
}

# Collecting the candidates in a foreach list aliases a %ENV element, which
# vivifies it: a plain logdir() call must not leave LOGDIR in the environment.
NO_ENV_LEAK: {
	delete $ENV{'LOGDIR'};

	my $i = new_ok('CGI::Info');
	$i->logdir();
	ok(!defined($ENV{'LOGDIR'}), 'logdir() does not add LOGDIR to the environment');
}

# A directory whose name is "0" is false in Perl but is still a valid
# directory, so it must be accepted rather than treated as a get.
# An empty string is still treated as a get.
ZERO_NAMED_DIR: {
	use File::Temp qw(tempdir);
	use Cwd qw(getcwd);

	my $cwd = getcwd();
	my $tmp = tempdir(CLEANUP => 1);
	chdir($tmp) or die "chdir $tmp: $!";
	mkdir('0') or die "mkdir 0: $!";

	my $i = new_ok('CGI::Info');
	is($i->logdir('0'), '0', 'logdir("0") sets a directory named 0');
	is($i->logdir(''), '0', 'logdir("") is a get, not a set');

	chdir($cwd) or die "chdir $cwd: $!";
}
