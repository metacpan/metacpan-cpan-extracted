use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME => 'App::Test::Generator',
	VERSION_FROM => 'lib/App/Test/Generator.pm',
	ABSTRACT_FROM => 'lib/App/Test/Generator.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'GPL',
	EXE_FILES => ['bin/fuzz-harness-generator'],
	MIN_PERL_VERSION => '5.014',
	PREREQ_PM => {
		'autodie' => 0,
		'Test::Most' => 0,
		'Params::Get' => 0,
		'Params::Validate::Strict' => 0,
		'Return::Set' => 0,
		'YAML::XS' => 0,
		'File::Slurp' => 0,
		'Getopt::Long' => 0,
		'Pod::Usage' => 0,
	},
	TEST_REQUIRES => {
		'File::Glob' => 0,
		'File::stat' => 0,
		'File::Temp' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'Test::DescribeMe' => 0,
		'Test::More' => 0,
		'Test::Needs' => 0,
		'Test::Returns' => 0.02
	}, dist => $dist,
	clean	 => { FILES => 'App-Test-Generator-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/App::Test::Generator',
			repository => {
				repository => 'https://github.com/nigelhorne/App-Test-Generator',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-Test-Generator.git',
				web => 'https://github.com/nigelhorne/App-Test-Generator',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-App-Test-Generator@rt.cpan.org',
				url => 'https://github.com/nigelhorne/App-Test-Generator/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Test-Generator',
				web => 'https://github.com/nigelhorne/App-Test-Generator/issues'
			}
		},
	},
);
