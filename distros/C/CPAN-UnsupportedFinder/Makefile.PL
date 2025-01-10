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
	NAME => 'CPAN::UnsupportedFinder',
	VERSION_FROM => 'lib/CPAN/UnsupportedFinder.pm', # finds $VERSION in the module
	AUTHOR => 'Nigel Horne <njh@bandsman.co.uk>',
	ABSTRACT => 'Identifies unsupported or poorly maintained CPAN modules by analyzing CPAN Testers data and release info.',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PREREQ_PM => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'HTTP::Tiny' => 0,
		'JSON::MaybeXS' => 0,
		'Carp' => 0,
		'Log::Log4perl' => 0,
		'Scalar::Util' => 0,
	},
	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/nigelhorne/CPAN-UnsupportedFinder.git',
				web => 'https://github.com/nigelhorne/CPAN-UnsupportedFinder',
			},
			bugtracker => {
				web => 'https://github.com/nigelhorne/CPAN-UnsupportedFinder/issues',
			},
		},
	},
	TEST_REQUIRES => {
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::HTML::Lint' => 0,
		'Test::JSON' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::RequiresInternet' => 0,
		'Test::Warnings' => 0
	}, dist => $dist,
	clean => { FILES => 'CPAN-UnsupportedFinder-*' },  # Clean up distribution files
);
