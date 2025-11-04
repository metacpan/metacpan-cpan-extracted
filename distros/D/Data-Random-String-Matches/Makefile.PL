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
	NAME		=> 'Data::Random::String::Matches',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Data/Random/String/Matches.pm',
	ABSTRACT_FROM	=> 'lib/Data/Random/String/Matches.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	},
	EXE_FILES => ['bin/random-string', 'bin/cookbook'],
	PREREQ_PM => {
		'Carp' => 0,
		'Getopt::Long' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Params::Get' => 0.13,
		'Pod::Usage' => 0,
	}, TEST_REQUIRES => {
		'File::Glob' => 0,
		'File::Slurp' => 0,
		'File::stat' => 0,
		'File::Temp' => 0,
		'IPC::Run3' => 0,
		'IPC::System::Simple' => 0,
		'JSON::MaybeXS' => 0,
		'POSIX' => 0,
		'Readonly' => 0,
		'strict' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'warnings' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'Data-Random-String-Matches-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Data::Random::String::Matches',
			repository => {
				repository => 'https://github.com/nigelhorne/Data-Random-String-Matches',
				type => 'git',
				url => 'git://github.com/nigelhorne/Data-Random-String-Matches.git',
				web => 'https://github.com/nigelhorne/Data-Random-String-Matches',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Data-Random-String-Matches@rt.cpan.org',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Random-String-Matches',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Random-String-Matches',
				# url => 'https://github.com/nigelhorne/Data-Random-String-Matches/issues',
				# web => 'https://github.com/nigelhorne/Data-Random-String-Matches/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.010'
);
