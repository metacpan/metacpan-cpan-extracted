#!/usr/bin/env perl

use strict;
use warnings;

# Regression tests for what a generated harness expects when a routine reports
# invalid input:
#
#   - an argument the code refuses when empty (_not_empty) must be given an
#     empty value that expects a death, not a survival case, and
#   - a case that expects a death is satisfied by the documented undef return
#     (_error_return: undef) rather than failing because the routine did not
#     croak.
#
# Both are silent when they work and only show up as a failing generated test,
# so each rule is checked against a control harness built from a schema without
# it: the control must fail, otherwise the test would pass for the wrong
# reason.

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use Test::Most;

use App::Test::Generator ();

my $tmpdir = tempdir(CLEANUP => 1);
my $lib_dir = File::Spec->catdir($tmpdir, 'lib');
my $schema_dir = File::Spec->catdir($tmpdir, 'schema');
my $out_dir = File::Spec->catdir($tmpdir, 'out');
my $work_dir = File::Spec->catdir($tmpdir, 'work');
make_path($schema_dir, $out_dir, $work_dir, File::Spec->catdir($lib_dir, 'Tolerant'));

my $module = <<'MODULE';
package Tolerant::Fixture;

use strict;
use warnings;

sub new
{
	my ($class) = @_;

	return bless {}, $class;
}

# Refuses empty bytes, as the code pattern the extractor reads.
sub store
{
	my ($self, $spec, $mtime, $size, $bytes) = @_;

	die 'bytes are required' unless defined $bytes && length $bytes;

	return 'stored:' . $spec;
}

# Reports invalid input as undef rather than dying.
sub first_total
{
	my ($rows) = @_;

	return undef unless @$rows;

	return $rows->[0];
}

1;
MODULE

{
	my $pm = File::Spec->catfile($lib_dir, 'Tolerant', 'Fixture.pm');
	open my $fh, '>', $pm or die "$pm: $!";
	print {$fh} $module;
	close $fh or die "$pm: $!";
}

# Generate a harness from the schema and run it from the scratch directory,
# returning the emitted code and what the harness printed.
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
	chdir $cwd or die "$cwd: $!";

	return { code => $code, out => ($stdout // '') . ($stderr // '') };
}

# The bytes argument is the one the code refuses when empty; the other three
# are optional so the empty value is the only one under test.
sub _store_schema
{
	my ($not_empty) = @_;

	my $empty = $not_empty ? "    _not_empty: 1\n" : '';

	return <<"YAML";
---
module: Tolerant::Fixture
function: store

config:
  test_undef: no
  test_empty: yes

input:
  spec:
    type: string
    position: 0
    optional: 1
  mtime:
    type: string
    position: 1
    optional: 1
  size:
    type: string
    position: 2
    optional: 1
  bytes:
    type: string
    position: 3
$empty
new: {}

output:
  type: string
YAML
}

sub _first_total_schema
{
	my ($error_return) = @_;

	my $report = $error_return ? "  _error_return: undef\n" : '';

	return <<"YAML";
---
module: Tolerant::Fixture
function: first_total

config:
  test_undef: no

input:
  rows:
    type: arrayref
    position: 0
    min: 1

output:
  type: string
$report
YAML
}

my %harness = (
	store => _generate('store', _store_schema(1)),
	store_lax => _generate('store_lax', _store_schema(0)),
	first_total => _generate('first_total', _first_total_schema(1)),
	first_total_strict => _generate('first_total_strict', _first_total_schema(0)),
);

subtest 'an argument refused when empty is expected to die' => sub {
	my $strict = $harness{store}{out};
	my $lax = $harness{store_lax}{out};

	like($strict, qr/^1\.\.\d+/m, 'harness ran to completion');
	like($strict, qr/^ok \d+ - store\(, , , \) dies \(position test, status = DIES\)/m,
		'the empty value is a case that is expected to die');
	unlike($strict, qr/^not ok \d+/m,
		'and no generated case passes an empty value expecting a clean return');
	unlike($lax, qr/^ok \d+ - store\(, , , \) dies \(position test/m,
		'the control without _not_empty does not expect that death');
	like($lax, qr/^not ok \d+ - store\(, , , \)/m,
		'so the control fails on the empty value');

	my $strict_failures = () = $strict =~ /^not ok \d+/mg;
	my $lax_failures = () = $lax =~ /^not ok \d+/mg;
	is($strict_failures, 0, 'every case the schema generated passes');
	cmp_ok($lax_failures, '>', 0, 'while the control fails on the empty value');
};

subtest 'a must-die case accepts the documented undef return' => sub {
	like($harness{first_total}{out}, qr/^1\.\.\d+/m, 'harness ran to completion');
	unlike($harness{first_total}{out}, qr/^not ok \d+/m,
		'returning undef satisfies the case that expects a death');
	like($harness{first_total_strict}{out}, qr/^not ok \d+/m,
		'the control without _error_return fails on the same case');
};

done_testing();
