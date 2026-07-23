use strict;
use warnings;
use Test::Most;
use File::Temp qw(tempdir);
use Path::Tiny;
use App::makefilepl2cpanfile;

# generate() must croak — not silently return — when the makefile is missing.
eval { App::makefilepl2cpanfile::generate(makefile => '/nonexistent/path/Makefile.PL') };
like $@, qr/Cannot read/, 'generate() croaks with "Cannot read" for missing makefile';

# generate() must croak when the path exists but is a directory, not a file.
{
	my $dir = tempdir(CLEANUP => 1);
	eval { App::makefilepl2cpanfile::generate(makefile => $dir) };
	like $@, qr/Cannot read/, 'generate() croaks when path is a directory';
}

# generate() must succeed with a minimal, valid Makefile.PL.
{
	my $dir = tempdir(CLEANUP => 1);
	path($dir)->child('Makefile.PL')->spew_utf8(
		"WriteMakefile(PREREQ_PM => { 'Scalar::Util' => 0 });\n"
	);

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => path($dir)->child('Makefile.PL')->stringify,
			with_develop => 0,
		);
	} 'generate() lives with a valid minimal Makefile.PL';

	like $out, qr/requires 'Scalar::Util'/, 'output contains the expected module';
}

# generate() with with_develop => 0 must not emit a develop block at all.
{
	my $dir = tempdir(CLEANUP => 1);
	path($dir)->child('Makefile.PL')->spew_utf8(
		"WriteMakefile(PREREQ_PM => { 'Carp' => 0 });\n"
	);

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => path($dir)->child('Makefile.PL')->stringify,
		with_develop => 0,
	);
	unlike $out, qr/on 'develop'/, 'no develop block emitted when with_develop is false';
}

done_testing;
