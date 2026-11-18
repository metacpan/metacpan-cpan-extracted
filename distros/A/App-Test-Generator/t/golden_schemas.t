#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/golden_schemas.t - golden schemas for a few real distributions.
#
# Extraction is run over sibling checkouts (../CGI-Info and friends) and
# the resulting schemas are compared with the committed goldens under
# t/golden/.  A change in the extractor that alters a schema now shows up
# as a reviewable diff instead of passing unnoticed.
#
# The distributions are not part of this repository and are absent in CI,
# so each one is skipped when its checkout is not present.
#
# Regenerate after an intended schema change:
#     UPDATE_GOLDEN=1 prove -l t/golden_schemas.t
#
# Volatile output is normalised away: the YAML comments include the
# output path, and compiled regexes are compared by their string form.
# ======================================================================

use Test::Most;
use Config;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;
use YAML::XS ();

my $lib = abs_path(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
my $script = abs_path(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'extract-schemas'));
my $root = abs_path(File::Spec->catdir($Bin, File::Spec->updir(), File::Spec->updir()));
my $golden_dir = File::Spec->catdir($Bin, 'golden');

my @distributions = (
	{ label => 'cgi-info',             dir => 'CGI-Info',             module => 'lib/CGI/Info.pm' },
	{ label => 'database-abstraction', dir => 'Database-Abstraction', module => 'lib/Database/Abstraction.pm' },
	{ label => 'lingua-en-namecase',   dir => 'Lingua-EN-NameCase',   module => 'lib/Lingua/EN/NameCase.pm' },
	{ label => 'geo-coder-free',       dir => 'Geo-Coder-Free',       module => 'lib/Geo/Coder/Free.pm' },
	{ label => 'ham-dxcc-lookup',      dir => 'Ham-DXCC-Lookup',      module => 'lib/Ham/DXCC/Lookup.pm' },
	{ label => 'genealogy-wills',      dir => 'Genealogy-Wills',      module => 'lib/Genealogy/Wills.pm' },
);

# These distributions are separate repositories, absent in CI and from a
# fresh checkout of this one.  Without any of them there is nothing to
# compare, and skipping is correct.
my $present = grep { -f File::Spec->catfile($root, $_->{dir}, $_->{module}) } @distributions;
plan skip_all => 'No local checkouts of the golden distributions' unless $present;

ok(-f $script, 'extract-schemas is where the test expects it') or BAIL_OUT('cannot find extract-schemas');
ok(-d $golden_dir, 'the golden directory exists') or BAIL_OUT("cannot find $golden_dir");

# A compiled regex is a reference, not data a YAML dump can compare across
# processes; its string form is stable and is what the schema means.
sub _normalise
{
	my ($value) = @_;

	if(ref($value) eq 'HASH') {
		return { map { $_ => _normalise($value->{$_}) } keys %{$value} };
	} elsif(ref($value) eq 'ARRAY') {
		return [ map { _normalise($_) } @{$value} ];
	} elsif(ref($value) eq 'Regexp') {
		return "$value";
	}

	return $value;
}

sub _canonical
{
	my (%routines) = @_;

	no warnings 'once';	# $YAML::XS::SortKeys is set only here
	local $YAML::XS::SortKeys = 1;
	return YAML::XS::Dump(\%routines);
}

sub _first_difference
{
	my ($expected, $actual) = @_;

	my @expected = split(/\n/, $expected);
	my @actual = split(/\n/, $actual);
	my $last = @expected > @actual ? scalar(@expected) : scalar(@actual);

	for my $i (0 .. $last - 1) {
		return $i if !defined($expected[$i]) || !defined($actual[$i]) || $expected[$i] ne $actual[$i];
	}

	return undef;
}

sub _extract
{
	my ($distribution, $tempdir) = @_;

	my $out = File::Spec->catdir($tempdir, $distribution->{label});
	make_path($out);

	my $module = File::Spec->catfile($root, $distribution->{dir}, $distribution->{module});
	return undef unless -f $module;

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join($Config{path_sep}, $lib, File::Spec->catdir($root, $distribution->{dir}, 'lib'), $ENV{PERL5LIB} // '');
	run3([$^X, "-I$lib", $script, '--output-dir', $out, $module], \undef, \$stdout, \$stderr);

	if($? >> 8) {
		fail("$distribution->{label}: extract-schemas failed") or diag("stdout:\n$stdout\nstderr:\n$stderr");
		return undef;
	}

	my %routines;
	for my $file (sort glob(File::Spec->catfile($out, '*.yml'))) {
		(my $name = $file) =~ s{.*/}{};
		$name =~ s{\.yml\z}{};
		$routines{$name} = _normalise(YAML::XS::LoadFile($file));
	}

	if(!keys %routines) {
		fail("$distribution->{label}: extraction produced no schemas");
		return undef;
	}

	return \%routines;
}

my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $ran = 0;

for my $distribution (@distributions) {
	SKIP: {
		my $module = File::Spec->catfile($root, $distribution->{dir}, $distribution->{module});
		skip("no local checkout of $distribution->{dir}", 1) unless -f $module;

		$ran++;
		my $routines = _extract($distribution, $tempdir);
		next unless $routines;

		my $canonical = _canonical(%{$routines});
		my $golden_file = File::Spec->catfile($golden_dir, "$distribution->{label}.yml");

		if($ENV{UPDATE_GOLDEN}) {
			open(my $fh, '>', $golden_file) or die "cannot write $golden_file: $!";
			print {$fh} $canonical;
			close($fh) or die "cannot close $golden_file: $!";
			pass("$distribution->{label}: golden updated");
			next;
		}

		if(!-f $golden_file) {
			fail("$distribution->{label}: no golden at $golden_file");
			diag('Create it with UPDATE_GOLDEN=1 prove -l t/golden_schemas.t');
			next;
		}

		open(my $fh, '<', $golden_file) or die "cannot read $golden_file: $!";
		local $/;
		my $golden = <$fh>;
		close($fh) or die "cannot close $golden_file: $!";

		if($canonical eq $golden) {
			pass("$distribution->{label}: schemas match the golden");
		} else {
			my $line = _first_difference($golden, $canonical);
			my @golden_lines = split(/\n/, $golden);
			my @canonical_lines = split(/\n/, $canonical);
			fail("$distribution->{label}: schemas changed");
			diag("first difference at line " . (defined($line) ? $line + 1 : 'end of file'));
			diag("golden:    " . (defined($golden_lines[$line]) ? $golden_lines[$line] : '(missing)'));
			diag("generated: " . (defined($canonical_lines[$line]) ? $canonical_lines[$line] : '(missing)'));
			diag("If the change is intended, rerun with UPDATE_GOLDEN=1.");
		}
	}
}

ok($ran > 0, 'at least one local distribution was checked') if $present;

done_testing();
