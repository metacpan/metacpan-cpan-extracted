#!/usr/bin/env perl

# The running script must never be read as its own configuration.
#
# The script's name is one of the files Config::Abstraction looks for, and a
# file no other parser understands falls through to Config::Auto, which evals
# it as Perl.  So a program whose configuration directory was its own directory
# (CONFIG_DIR=$(pwd)) ran itself again, inside itself, while it was still
# loading - and the errors that caused were swallowed.
#
# This file is the running script in the first test, so if the guard fails it
# is evaluated as configuration: the block below notices and stops at once.

if($main::SELF_LOAD_RUNNING) {
	$main::SELF_LOAD_REENTERED++;
	return {};
}
$main::SELF_LOAD_RUNNING = 1;

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(basename dirname);
use File::Slurp qw(write_file);
use File::Spec;
use Readonly;
use Test::Most;
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

Readonly my $SCRIPT => abs_path($0);
Readonly my $SCRIPT_NAME => basename($0);

our ($SELF_LOAD_REENTERED, $PROGRAM_RAN);

# new() returns undef when it finds no configuration at all
sub load
{
	my $config = Config::Abstraction->new(@_);
	return $config ? $config->all() : {};
}

subtest 'directory holding the script' => sub {
	# CONFIG_DIR=$(pwd): the script's name is found in a configuration
	# directory given as an absolute path, which the old name-in-curdir
	# check did not catch
	$SELF_LOAD_REENTERED = 0;
	my $config = load(config_dirs => [dirname($SCRIPT)]);
	is($SELF_LOAD_REENTERED, 0, 'script not evaluated as configuration');
	ok(!(grep { abs_path($_) eq $SCRIPT } @{$config->{'config_path'} // []}), 'script not in config_path');
};

subtest 'symlink to the script' => sub {
	# Another name for the same file is still the same file
	my $dir = tempdir();
	my $link = File::Spec->catfile($dir, $SCRIPT_NAME);
	plan(skip_all => 'symlinks are not available') unless(eval { symlink($SCRIPT, $link) });

	$SELF_LOAD_REENTERED = 0;
	load(config_dirs => [$dir]);
	is($SELF_LOAD_REENTERED, 0, 'script not evaluated through a symlink');
};

subtest 'a program is never configuration' => sub {
	# A file starting with #! is a program whatever its name: the Perl
	# parser must not run it
	my $dir = tempdir();
	write_file(File::Spec->catfile($dir, 'program'), "#!/usr/bin/perl\n\$main::PROGRAM_RAN = 1;\n{ key => 'value' };\n");

	$PROGRAM_RAN = 0;
	my $config = load(config_dirs => [$dir], config_file => 'program');
	is($PROGRAM_RAN, 0, 'program not run');
	ok(!exists($config->{'key'}), 'nothing loaded from it');
};

subtest 'a configuration file that shares the script name is still read' => sub {
	# Only the script itself is refused: a real configuration file of the
	# same name in another directory is what the name lookup is for
	my $dir = tempdir();
	write_file(File::Spec->catfile($dir, $SCRIPT_NAME), "shared_name: loaded\n");

	my $config = load(config_dirs => [$dir]);
	is($config->{'shared_name'}, 'loaded', 'file of the same name elsewhere is loaded');
};

done_testing();
