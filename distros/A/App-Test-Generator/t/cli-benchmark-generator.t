use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use File::Spec;
use IPC::Run3;
use FindBin;

my $script = File::Spec->catfile($FindBin::Bin, '..', 'bin', 'benchmark-generator');
ok(-e $script, 'benchmark-generator exists');
ok(-x $script, 'benchmark-generator is executable') if $^O ne 'MSWin32';

my $valid_schema = 't/conf/abs.yml';
ok(-e $valid_schema, 'abs.yml test schema exists');

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
	like($out, qr/Usage:|SYNOPSIS/i, '--help output contains usage info');
}

# --version
{
	my ($exit, $out) = run_cmd($script, '--version');
	is($exit, 0, '--version exits cleanly');
	like($out, qr/\d+\.\d+/, '--version prints a version string');
}

# stdout mode — no --output flag
{
	my ($exit, $out, $err) = run_cmd($script, '-i', $valid_schema);
	is($exit, 0, 'stdout mode exits cleanly');
	like($out, qr/cmpthese/,          'output contains cmpthese');
	like($out, qr/#!/,                 'output starts with shebang');
	like($out, qr/abs/,                'output mentions the function name');
	is($err,   '',                     'no stderr in stdout mode');
}

# --output writes a file
{
	my ($fh, $outfile) = tempfile(SUFFIX => '.pl', UNLINK => 1);
	close $fh;
	unlink $outfile;

	my ($exit) = run_cmd($script, '-i', $valid_schema, '-o', $outfile);
	is($exit, 0, '--output exits cleanly');
	ok(-e $outfile,       'output file created');
	ok(-s $outfile,       'output file is non-empty');

	my $content = do { local $/; open my $r, '<', $outfile or die $!; <$r> };
	like($content, qr/cmpthese/, 'written file contains cmpthese');
}

# transforms from schema become named variants
{
	my ($exit, $out) = run_cmd($script, '-i', $valid_schema);
	is($exit, 0, 'transform schema exits cleanly');
	# abs.yml has positive and negative transforms
	like($out, qr/'positive'/, 'positive transform variant present');
	like($out, qr/'negative'/, 'negative transform variant present');
}

# representative values respect range constraints
{
	my ($exit, $out) = run_cmd($script, '-i', $valid_schema);
	is($exit, 0, 'exits cleanly for range-constrained schema');
	# negative transform has max => 0 so representative value must be <= 0
	like($out, qr/abs\(-\d+\)/, 'negative-constrained variant calls abs with a negative value');
}

# missing input file fails gracefully
{
	my ($exit, undef, $err) = run_cmd($script, '-i', 't/conf/does_not_exist.yml');
	isnt($exit, 0, 'missing schema causes non-zero exit');
}

# generated script is valid Perl
{
	my ($fh, $outfile) = tempfile(SUFFIX => '.pl', UNLINK => 1);
	close $fh;

	run_cmd($script, '-i', $valid_schema, '-o', $outfile);
	# run_cmd prepends $^X -Ilib already; pass only the -c flag and file
	my ($exit) = run_cmd('-c', $outfile);
	is($exit, 0, 'generated benchmark script passes perl -c');
}

done_testing();
