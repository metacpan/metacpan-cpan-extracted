#!/usr/bin/env perl

use strict;
use warnings;

# Regression test for wrong-type cases on documented scalar parameters.
#
# A type that only the documentation declares (_source pod/input_spec) is
# intent, not a check the routine was seen to make.  The harness already
# treated strings, hashrefs and arrayrefs that way; integers, floats and
# booleans still got "wrong type must die" cases, so a constructor that
# documents its arguments without validating them (CGI::Info::new) failed
# thousands of cases.  A hand-written schema has no marker and stays strict.

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use Test::Most;

use App::Test::Generator;

my $tmpdir = tempdir(CLEANUP => 1);
my $lib_dir = File::Spec->catdir($tmpdir, 'lib');
my $schema_dir = File::Spec->catdir($tmpdir, 'schema');
my $out_dir = File::Spec->catdir($tmpdir, 'out');
my $work_dir = File::Spec->catdir($tmpdir, 'work');
make_path($schema_dir, $out_dir, $work_dir, File::Spec->catdir($lib_dir, 'Lenient'));

my $module_file = File::Spec->catfile($lib_dir, 'Lenient', 'Fixture.pm');
open my $module_fh, '>', $module_file or die "$module_file: $!";
print {$module_fh} <<'MODULE';
package Lenient::Fixture;

use strict;
use warnings;

# Documents its arguments, validates none of them
sub configure
{
	my %args = @_;

	return scalar(keys %args);
}

1;
MODULE
close $module_fh or die "$module_file: $!";

sub _schema
{
	my $source = shift;

	my $marker = defined($source) ? "\n    _source: $source" : '';

	return <<"YAML";
---
module: Lenient::Fixture
function: configure

config:
  test_undef: no
  test_empty: no

input:
  count:
    type: integer
    optional: 1$marker
  ratio:
    type: float
    optional: 1$marker
  flag:
    type: boolean
    optional: 1$marker

output:
  type: integer
YAML
}

# Generate a harness, run it from a scratch directory and return its output
sub _run
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

	my @inc = map { '-I' . File::Spec->rel2abs($_) } grep { !ref } @INC;
	my $cwd = getcwd();
	my ($stdout, $stderr) = ('', '');
	chdir $work_dir or die "$work_dir: $!";
	run3 [ $^X, @inc, "-I$lib_dir", $harness ], undef, \$stdout, \$stderr;
	my $exit = $? >> 8;
	chdir $cwd or die "$cwd: $!";

	return { exit => $exit, out => ($stdout // '') . ($stderr // '') };
}

foreach my $source (qw(input_spec pod)) {
	subtest "types documented by $source are not expected to be enforced" => sub {
		my $run = _run("documented_$source", _schema($source));

		is($run->{exit}, 0, 'the harness passes against a routine that validates nothing')
			or diag(join("\n", grep { !/^ok / } split(/\n/, $run->{out})));
		unlike($run->{out}, qr/^not ok/m, 'no case failed');
		unlike($run->{out}, qr/=> '?(?:xyzzy|0x10|1_000)'?\) dies/,
			'no wrong-type value was required to die');
	};
}

subtest 'a hand-written schema still expects the wrong type to die' => sub {
	my $run = _run('handwritten', _schema(undef));

	isnt($run->{exit}, 0, 'the harness fails against a routine that validates nothing');
	like($run->{out}, qr/^not ok .*count.* dies/m, 'a wrong-type integer was required to die');
	like($run->{out}, qr/^not ok .*ratio.* dies/m, 'a wrong-type float was required to die');
	like($run->{out}, qr/^not ok .*flag.* dies/m, 'a wrong-type boolean was required to die');
};

done_testing();
