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
	NAME		=> 'App::makefilepl2cpanfile',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/App/makefilepl2cpanfile.pm',
	ABSTRACT_FROM	=> 'lib/App/makefilepl2cpanfile.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	EXE_FILES => ['bin/makefilepl2cpanfile'],
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'File::Temp' => 0,
		'Test::NoWarnings' => 0,
		'Test::RequiresInternet' => 0,
		'Test::Which' => 0,
		'Test::Returns' => 0,
		'Test::Warn' => 0,
	}, PREREQ_PM => {
		'File::HomeDir' => 0,
		'File::Slurp' => 0,
		'YAML::Tiny' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'App-makefilepl2cpanfile-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/App::makefilepl2cpanfile',
			repository => {
				repository => 'https://github.com/nigelhorne/App-makefilepl2cpanfile',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-makefilepl2cpanfile.git',
				web => 'https://github.com/nigelhorne/App-makefilepl2cpanfile',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-App-makefilepl2cpanfile@rt.cpan.org',
				url => 'https://github.com/nigelhorne/App-makefilepl2cpanfile/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-makefilepl2cpanfile',
				web => 'https://github.com/nigelhorne/App-makefilepl2cpanfile/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
