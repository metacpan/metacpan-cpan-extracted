#!/usr/bin/env perl

use strict;
use warnings;

# Regression test for what a generated harness checks a routine leaves behind:
#
#   - files in the working directory ("no files left in cwd"), gated by the
#     config key check_files, and
#   - open file descriptors ("no file descriptors leaked"), gated by check_fds.
#
# Both pass silently for a well-behaved routine, so the generator could stop
# emitting them, or stop honouring the config keys, without any other test
# noticing.  The module under test and its schemas are written to a temporary
# directory, and each harness is run from a scratch directory of its own.

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use Readonly;
use Test::Most;

use App::Test::Generator;

Readonly my $FILES_MESSAGE => 'no files left in cwd';
Readonly my $FDS_MESSAGE => 'no file descriptors leaked';
Readonly my $FD_DIR => '/proc/self/fd';

my $tmpdir = tempdir(CLEANUP => 1);
my $lib_dir = File::Spec->catdir($tmpdir, 'lib');
my $schema_dir = File::Spec->catdir($tmpdir, 'schema');
my $out_dir = File::Spec->catdir($tmpdir, 'out');
my $work_dir = File::Spec->catdir($tmpdir, 'work');
make_path($schema_dir, $out_dir, $work_dir, File::Spec->catdir($lib_dir, 'Destructive'));

my $module = <<'MODULE';
package Destructive::Fixture;

use strict;
use warnings;

my @held;

# Leaves nothing behind
sub tidy
{
	my $n = shift;

	return $n * 2;
}

# Leaves a file in the working directory
sub litter
{
	my $n = shift;

	open(my $fh, '>', "litter.$$.tmp") or die "litter.$$.tmp: $!";
	print {$fh} $n;
	close $fh;
	return $n * 2;
}

# Keeps a filehandle open after it returns.  Only the first few calls leak:
# a harness makes thousands of calls, and one descriptor each would run into
# the per-process limit (256 on macOS) and kill the harness with EMFILE.
sub hoard
{
	my $n = shift;

	if(@held < 4) {
		open(my $fh, '<', $INC{'Destructive/Fixture.pm'}) or die "$!";
		push @held, $fh;
	}
	return $n * 2;
}

1;
MODULE

my $module_file = File::Spec->catfile($lib_dir, 'Destructive', 'Fixture.pm');
open my $module_fh, '>', $module_file or die "$module_file: $!";
print {$module_fh} $module;
close $module_fh or die "$module_file: $!";

sub _schema
{
	my ($function, $extra_config) = @_;

	$extra_config //= '';

	return <<"YAML";
---
module: Destructive::Fixture
function: $function

config:
  test_undef: no
  test_empty: no
$extra_config
input:
  number:
    type: number
    position: 0

output:
  type: number
YAML
}

# Generate a harness, run it from the scratch directory, and return the
# emitted code, what it printed, and what it left in that directory
sub _generate
{
	my ($name, $yaml) = @_;

	my $schema = File::Spec->catfile($schema_dir, "$name.yml");
	open my $schema_fh, '>', $schema or die "$schema: $!";
	print {$schema_fh} $yaml;
	close $schema_fh or die "$schema: $!";

	my $harness = File::Spec->catfile($out_dir, "$name.t");
	{
		local @INC = (@INC, $lib_dir);
		App::Test::Generator->generate($schema, $harness);
	}
	die "harness $name.t was not written" unless -s $harness;

	open my $harness_fh, '<', $harness or die "$harness: $!";
	my $code = do { local $/; <$harness_fh> };
	close $harness_fh;

	my @inc = map { '-I' . File::Spec->rel2abs($_) } grep { !ref } @INC;
	my $cwd = getcwd();
	my ($stdout, $stderr) = ('', '');
	chdir $work_dir or die "$work_dir: $!";
	run3 [ $^X, @inc, "-I$lib_dir", $harness ], undef, \$stdout, \$stderr;
	opendir(my $dh, $work_dir) or die "$work_dir: $!";
	my @left = grep { !/^\.\.?$/ } readdir $dh;
	closedir $dh;
	chdir $cwd or die "$cwd: $!";

	return { code => $code, out => ($stdout // '') . ($stderr // ''), left => \@left };
}

my %harness = (
	tidy => _generate('tidy', _schema('tidy')),
	litter => _generate('litter', _schema('litter')),
	litter_gated => _generate('litter_gated', _schema('litter', "  check_files: no\n")),
	hoard => _generate('hoard', _schema('hoard')),
	hoard_gated => _generate('hoard_gated', _schema('hoard', "  check_fds: no\n")),
);

subtest 'the harness carries both checks' => sub {
	like($harness{tidy}{code}, qr/\Q$FILES_MESSAGE\E/, 'leftover files are checked');
	like($harness{tidy}{code}, qr/\Q$FDS_MESSAGE\E/, 'file descriptors are checked');
	like($harness{tidy}{out}, qr/^1\.\.\d+/m, 'harness ran to completion');
};

subtest 'a routine that leaves nothing behind is not reported' => sub {
	unlike($harness{tidy}{out}, qr/^not ok \d+ - \Q$FILES_MESSAGE\E/m, 'no leftover files reported');
	unlike($harness{tidy}{out}, qr/^not ok \d+ - \Q$FDS_MESSAGE\E/m, 'no leaked descriptors reported');
};

subtest 'a routine that leaves a file behind is reported' => sub {
	like($harness{litter}{out}, qr/^not ok \d+ - \Q$FILES_MESSAGE\E/m, 'the leftover file is reported');
	is_deeply($harness{litter}{left}, [], 'the harness removed the file');
};

subtest 'check_files: no silences the report but still cleans up' => sub {
	like($harness{litter_gated}{out}, qr/^1\.\.\d+/m, 'harness ran to completion');
	unlike($harness{litter_gated}{out}, qr/^not ok \d+ - \Q$FILES_MESSAGE\E/m, 'not reported');
	unlike($harness{litter_gated}{out}, qr/^ok \d+ - \Q$FILES_MESSAGE\E/m, 'the check is not run at all');
	is_deeply($harness{litter_gated}{left}, [], 'the harness still removed the file');
};

subtest 'a routine that keeps a descriptor open is reported' => sub {
	SKIP: {
		skip "$FD_DIR is not available on this platform", 1 unless -d $FD_DIR;
		like($harness{hoard}{out}, qr/^not ok \d+ - \Q$FDS_MESSAGE\E/m, 'the leaked descriptor is reported');
	}
};

subtest 'check_fds: no silences the report' => sub {
	like($harness{hoard_gated}{out}, qr/^1\.\.\d+/m, 'harness ran to completion');
	unlike($harness{hoard_gated}{out}, qr/^(?:not )?ok \d+ - \Q$FDS_MESSAGE\E/m, 'the check is not run at all');
};

done_testing();
