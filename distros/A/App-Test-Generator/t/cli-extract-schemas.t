use strict;
use warnings;

use Test::DescribeMe qw(extended);
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
	my ($exit, $out, $err) = run_cmd(
		$script,
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

done_testing();
