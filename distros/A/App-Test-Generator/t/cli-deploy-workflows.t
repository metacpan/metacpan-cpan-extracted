use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3;
use FindBin;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'deploy-workflows');
ok(-e $script, 'deploy-workflows script exists');
ok(-x $script, 'deploy-workflows is executable') if $^O ne 'MSWin32';

sub run_cmd {
	my (@cmd) = @_;
	my ($stdout, $stderr);
	run3([$^X, '-Ilib', @cmd], \undef, \$stdout, \$stderr);
	my $exit = $? >> 8;
	return ($exit, $stdout // '', $stderr // '');
}

# --help
{
	my ($exit, $out) = run_cmd($script, '--help');
	is($exit, 0, '--help exits cleanly');
	like($out, qr/Usage:|SYNOPSIS/i, '--help shows usage');
}

# --version
{
	my ($exit, $out) = run_cmd($script, '--version');
	is($exit, 0, '--version exits cleanly');
	like($out, qr/\d+\.\d+/, '--version prints a version number');
}

# --dry-run reports what would be written without creating files
{
	my $dir = tempdir(CLEANUP => 1);
	my ($exit, $out) = run_cmd($script, '--dry-run', '--target', $dir);
	is($exit, 0, '--dry-run exits cleanly');
	like($out, qr/dashboard\.yml/, '--dry-run mentions dashboard.yml');
	like($out, qr/mutate\.yml/,    '--dry-run mentions mutate.yml');
	ok(!-e File::Spec->catfile($dir, '.github', 'workflows', 'dashboard.yml'),
		'--dry-run does not create dashboard.yml');
	ok(!-e File::Spec->catfile($dir, '.github', 'workflows', 'mutate.yml'),
		'--dry-run does not create mutate.yml');
}

# normal deploy creates both files
{
	my $dir = tempdir(CLEANUP => 1);
	my ($exit, $out) = run_cmd($script, '--target', $dir);
	is($exit, 0, 'normal deploy exits cleanly');

	my $wf_dir = File::Spec->catdir($dir, '.github', 'workflows');
	ok(-d $wf_dir, '.github/workflows/ directory created');

	my $dash = File::Spec->catfile($wf_dir, 'dashboard.yml');
	my $mut  = File::Spec->catfile($wf_dir, 'mutate.yml');
	ok(-f $dash, 'dashboard.yml created');
	ok(-f $mut,  'mutate.yml created');
	ok(-s $dash, 'dashboard.yml is non-empty');
	ok(-s $mut,  'mutate.yml is non-empty');
}

# deployed dashboard.yml contains expected markers
{
	my $dir = tempdir(CLEANUP => 1);
	run_cmd($script, '--target', $dir);
	my $dash = File::Spec->catfile($dir, '.github', 'workflows', 'dashboard.yml');
	my $content = do { local $/; open my $fh, '<', $dash or die $!; <$fh> };
	like($content, qr/name:\s*Test Dashboard/,         'dashboard.yml has correct workflow name');
	like($content, qr/cmpthese|generate-test-dashboard/, 'dashboard.yml references the dashboard generator');
	like($content, qr/github\.event_name != 'pull_request'/, 'PR guard present in dashboard.yml');
}

# deployed mutate.yml contains expected markers
{
	my $dir = tempdir(CLEANUP => 1);
	run_cmd($script, '--target', $dir);
	my $mut = File::Spec->catfile($dir, '.github', 'workflows', 'mutate.yml');
	my $content = do { local $/; open my $fh, '<', $mut or die $!; $fh and <$fh> };
	like($content, qr/name:\s*Mutation Testing/, 'mutate.yml has correct workflow name');
	like($content, qr/test-generator-mutate/,    'mutate.yml references test-generator-mutate');
	like($content, qr/workflow_dispatch/,         'mutate.yml supports manual dispatch');
}

# second deploy without --force fails
{
	my $dir = tempdir(CLEANUP => 1);
	run_cmd($script, '--target', $dir);                         # first deploy
	my ($exit, undef, $err) = run_cmd($script, '--target', $dir);  # second
	isnt($exit, 0, 'second deploy without --force exits non-zero');
	like($err, qr/already exists|--force/i, 'error mentions --force');
}

# --force overwrites existing files
{
	my $dir = tempdir(CLEANUP => 1);
	run_cmd($script, '--target', $dir);
	my ($exit) = run_cmd($script, '--force', '--target', $dir);
	is($exit, 0, '--force allows overwriting existing files');
}

# --target missing directory fails
{
	my ($exit, undef, $err) = run_cmd($script, '--target', '/nonexistent/path/xyz');
	isnt($exit, 0, 'non-existent target fails');
	like($err, qr/does not exist|No such/i, 'error mentions missing directory');
}

# output includes next-steps hint
{
	my $dir = tempdir(CLEANUP => 1);
	my ($exit, $out) = run_cmd($script, '--target', $dir);
	like($out, qr/git add/,    'output hints at git add');
	like($out, qr/git commit/, 'output hints at git commit');
}

done_testing();
