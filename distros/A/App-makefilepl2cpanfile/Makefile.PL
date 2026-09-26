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
		? ('LICENSE'=> 'gpl_2')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	EXE_FILES => ['bin/makefilepl2cpanfile'],
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	}, TEST_REQUIRES => {
		'Capture::Tiny' => 0,
		'Module::CPANfile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Memory::Cycle' => 0,
		'Test::Most' => 0,
		'File::Temp' => 0,
		'Test::Mockingbird' => '0.13',	# around, mock_scoped, spy, unmock, restore
		'Test::Returns' => 0.04,
		'Test::Without::Module' => 0,
	}, PREREQ_PM => {
		'autodie' => 0,
		'File::HomeDir' => 0,
		'Path::Tiny' => '0.034',	# errors as Path::Tiny::Error objects
		'Params::Get' => 0.17,
		'IPC::System::Simple' => 0,
		'Readonly' => 0,
		'Text::Diff' => 0,
		'YAML::Tiny' => 0,
	}, dist => $dist,
	clean		=> { FILES => 'App-makefilepl2cpanfile-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		prereqs => {
			develop => {
				requires => {
					'Test::EOF'   => 0,	# t/eof.t (author test)
					'Test::EOL'   => 0,	# t/eol.t (author test)
					'Test::Kwalitee' => 0,	# t/kwalitee.t (author test)
					'Test::Needs' => 0,
				},
			},
		},
		resources => {
			homepage => 'https://metacpan.org/pod/App::makefilepl2cpanfile',
			repository => {
				repository => 'https://github.com/nigelhorne/App-makefilepl2cpanfile',
				type => 'git',
				url => 'git://github.com/nigelhorne/App-makefilepl2cpanfile.git',
				web => 'https://github.com/nigelhorne/App-makefilepl2cpanfile',
				# license => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				web => 'https://github.com/nigelhorne/App-makefilepl2cpanfile/issues',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.014'	# s///r and the /a regex modifier
);
