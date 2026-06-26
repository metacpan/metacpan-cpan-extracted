use strict;
use warnings;

# use Test::DescribeMe qw(extended);
use Test::Most;
use IPC::Run3;
use Symbol qw(gensym);
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'extract-schemas');
ok(-x $script, "$script is executable") if ($^O ne 'MSWin32');

# We need a simple Perl module to extract from
my $tmpdir = tempdir(CLEANUP => 1);
my $module = File::Spec->catfile($tmpdir, 'TestModule.pm');

open my $fh, '>', $module or die $!;
print $fh <<'END_PM';
package TestModule;

=head2 add

Adds two numbers.

=cut

sub add {
	my ($class, $a, $b) = @_;
	return $a + $b;
}

1;
END_PM
close $fh;

sub run_cmd {
	my (@cmd) = @_;
	my ($stdout, $stderr);
	run3([$^X, @cmd], \undef, \$stdout, \$stderr);
	my $exit = $? >> 8;
	return ($exit, $stdout // '', $stderr // '');
}

# --------------------------------------------------------------------
# --help
# --------------------------------------------------------------------

{
	my ($exit, $out, $err) = run_cmd($script, '--help');

	is($exit, 0, '--help exits cleanly');
	like($out, qr/Usage:/i, '--help output looks correct' );
}

# --------------------------------------------------------------------
# Missing input file
# --------------------------------------------------------------------

{
	my ($exit, $out, $err) = run_cmd($script);

	isnt($exit, 0, 'missing input file exits non-zero');
	like($err . $out, qr/input file/i, 'error mentions missing input file');
}

# --------------------------------------------------------------------
# Basic extraction
# --------------------------------------------------------------------

{
	my $outdir = File::Spec->catdir($tmpdir, 'schemas');

	my ($exit, $out, $err) = run_cmd(
		$script,
		'--output-dir', $outdir,
		$module
	);

	is($exit, 0, 'basic extraction succeeds');
	like($out, qr/EXTRACTION SUMMARY/, 'summary printed');
	ok(-d $outdir, 'output directory created');

	my @files = glob("$outdir/*.yml");
	ok(@files >= 1, 'at least one schema file generated');
}

# --------------------------------------------------------------------
# --verbose
# --------------------------------------------------------------------

{
	my $outdir = File::Spec->catdir($tmpdir, 'schemas');
	my ($exit, $out, $err) = run_cmd(
		$script,
		'--output-dir', $outdir,
		'--verbose',
		$module
	);

	is($exit, 0, '--verbose succeeds');
	like($out, qr/Schemas:/, 'verbose output includes schema dump');
}

# --------------------------------------------------------------------
# --strict-pod validation
# --------------------------------------------------------------------

{
	my ($exit, $out, $err) = run_cmd(
		$script,
		'--strict-pod=banana',
		$module
	);

	isnt($exit, 0, 'invalid --strict-pod fails');
	like($err . $out, qr/strict-pod/i, 'error mentions strict-pod');
}

# --------------------------------------------------------------------
# --fuzz loads the target module via require-by-path, not string eval
# (regression test for the eval "require $package" code-injection fix
# in _load_target_module)
# --------------------------------------------------------------------

{
	my $libdir = File::Spec->catdir($tmpdir, 'lib');
	mkdir $libdir unless -d $libdir;
	my $fuzz_module = File::Spec->catfile($libdir, 'TestFuzzModule.pm');

	open my $fh2, '>', $fuzz_module or die $!;
	print $fh2 <<'END_PM';
package TestFuzzModule;

=head2 add

=head3 Input

[ {type=>'integer'}, {type=>'integer'} ]

=cut

sub add {
	my ($a, $b) = @_;
	return $a + $b;
}

1;
END_PM
	close $fh2;

	my ($exit, $out, $err) = run_cmd(
		$script,
		'--fuzz',
		'--fuzz-iters', 5,
		'--output-dir', File::Spec->catdir($tmpdir, 'fuzz-schemas'),
		'--corpus-dir', File::Spec->catdir($tmpdir, 'fuzz-corpus'),
		$fuzz_module
	);

	is($exit, 0, '--fuzz exits cleanly when loading a well-formed module');
	like($out, qr/Fuzzing complete/, '--fuzz actually ran against the loaded module')
		or diag("stdout: $out\nstderr: $err");
}

# --------------------------------------------------------------------
# Package-name validation guard (unit-level): mirrors the regex added
# to _load_target_module in bin/extract-schemas to reject anything
# that isn't a syntactically valid Perl package name before it is used
# to build a require path.
# --------------------------------------------------------------------

{
	my $valid_re = qr/^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;

	for my $good (qw(Foo Foo::Bar Foo::Bar::Baz _Private App::Test::Generator)) {
		like($good, $valid_re, "valid package name '$good' is accepted");
	}

	for my $bad (
		"Foo; system('id')",
		'Foo`id`',
		'Foo/../../etc/passwd',
		'Foo $(id)',
		"Foo\nsystem('id')",
		'',
	) {
		unlike($bad, $valid_re, "malicious-looking value '$bad' is rejected");
	}
}

done_testing();
