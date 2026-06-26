use strict;
use warnings;

use Test::Most;
use IPC::Run3;
use File::Temp qw(tempdir);
use File::Spec;
use FindBin;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'extract-schemas2');
ok(-x $script, "$script is executable") if ($^O ne 'MSWin32');

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
# --emit-tests must not crash with "package required" from Planner->new
# (the package name is already derived from the module's `package`
# statement earlier in the script — it just wasn't being passed through).
# --------------------------------------------------------------------
{
	my $output_dir = File::Spec->catdir($tmpdir, 'schemas');
	my $test_dir    = File::Spec->catdir($tmpdir, 'generated');

	my ($exit, $out, $err) = run_cmd(
		$script, $module,
		'--output-dir', $output_dir,
		'--test-dir',   $test_dir,
		'--emit-tests',
	);

	is($exit, 0, '--emit-tests exits cleanly') or diag("stderr: $err");
	unlike($err, qr/package required/, 'Planner->new is given a package name');

	my $test_file = File::Spec->catfile($test_dir, '01-basic.t');
	ok(-e $test_file, 'generated test file was written');
}

done_testing();
