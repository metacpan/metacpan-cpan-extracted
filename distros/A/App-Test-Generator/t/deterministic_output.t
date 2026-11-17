#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/deterministic_output.t - extraction must not depend on hash order.
#
# Two runs over the same module, with different Perl hash seeds, must
# produce byte-identical YAML.  Parameter keys and the analysis notes in
# the comment block are sorted, so CI diffs stay readable and stable.
# ======================================================================

use Test::Most;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;

my $lib = abs_path(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
my $script = abs_path(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'extract-schemas'));
ok(-f $script, 'extract-schemas is where the test expects it') or BAIL_OUT('cannot find extract-schemas');

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $module_dir = File::Spec->catdir($dir, 'lib', 'Deterministic');
make_path($module_dir);

my $module_file = File::Spec->catfile($module_dir, 'Output.pm');
open(my $fh, '>', $module_file) or die "cannot write $module_file: $!";
print {$fh} <<'MODULE';
package Deterministic::Output;
use strict;
use warnings;

sub combine
{
	my ($zulu, $alpha, $mike, $bravo, $yankee, $charlie, $xray, $delta) = @_;

	return join(':', grep { defined } $zulu, $alpha, $mike, $bravo,
		$yankee, $charlie, $xray, $delta);
}

1;
MODULE
close($fh) or die "cannot close $module_file: $!";

my $out = File::Spec->catdir($dir, 'schemas');
make_path($out);

sub extract_with_seed
{
	my ($seed) = @_;

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join(':', $lib, File::Spec->catdir($dir, 'lib'), $ENV{PERL5LIB} // '');
	local $ENV{PERL_HASH_SEED} = $seed;
	local $ENV{PERL_PERTURB_KEYS} = 2;
	run3([$^X, "-I$lib", $script, '--output-dir', $out, $module_file], \undef, \$stdout, \$stderr);

	is($? >> 8, 0, "extract-schemas succeeded with PERL_HASH_SEED=$seed")
		or diag("stdout:\n$stdout\nstderr:\n$stderr");

	open(my $schema_fh, '<', File::Spec->catfile($out, 'combine.yml'))
		or die "cannot read combine.yml: $!";
	local $/;
	my $yaml = <$schema_fh>;
	close($schema_fh) or die "cannot close combine.yml: $!";

	return $yaml;
}

my $first = extract_with_seed(1);
my $second = extract_with_seed(2);

is($second, $first, 'different hash seeds produce identical YAML');

my @input_keys = $first =~ /^  (\w+):$/mg;
is_deeply(\@input_keys, [ sort @input_keys ], 'input parameter keys are sorted');
is(scalar(@input_keys), 8, 'all eight parameters are present');

my @notes = $first =~ /^#   - (\w+): /mg;
is(scalar(@notes), 8, 'every untyped parameter has a note');
is_deeply(\@notes, [ sort @notes ], 'analysis notes are sorted by parameter');

done_testing();
