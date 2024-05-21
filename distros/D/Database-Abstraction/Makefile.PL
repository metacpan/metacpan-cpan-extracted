use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'Database::Abstraction',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Database/Abstraction.pm',
	ABSTRACT_FROM	=> 'lib/Database/Abstraction.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'DBD::CSV' => 0,
		'DBD::XMLSimple' => 0.07,
		'File::Spec' => 0,
		'FindBin' => 0,
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Text::xSV::Slurp' => 0
	}, PREREQ_PM => {
		'autodie' => 0,
		'strict' => 0,
		'warnings' => 0,
		'Data::Dumper' => 0,
		'DBD::SQLite::Constants' => 0,
		'File::Basename' => 0,
		'File::Spec' => 0,
		'File::pfopen' => 0.02,
		'File::Temp' => 0,
		# 'Error' => 0,
		'Carp' => 0
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Database-Abstraction-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Database-Abstraction.git',
				web => 'https://github.com/nigelhorne/Database-Abstraction',
				repository => 'https://github.com/nigelhorne/Database-Abstraction',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Database-Abstraction',
				web => 'https://github.com/nigelhorne/Database-Abstraction/issues',
				url => 'https://github.com/nigelhorne/Database-Abstraction/issues',
				mailto => 'bug-Database-Abstraction@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
