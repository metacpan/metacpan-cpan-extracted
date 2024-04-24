use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'DateTime::Format::Genealogy',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/DateTime/Format/Genealogy.pm',
	ABSTRACT_FROM	   => 'lib/DateTime/Format/Genealogy.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Data::Dumper' => 0,
		'English' => 0,
		'File::Spec' => 0 ,
		'Test::CleanNamespaces' => 0,
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::Deep' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Warn' => 0,
		'strict' => 0,
		'warnings' => 0,
		'WWW::RT::CPAN' => 0
	}, PREREQ_PM => {
		'namespace::clean' => 0,
		'Carp' => 0,
		'DateTime::Format::Natural' => 0,
		'Genealogy::Gedcom::Date' => 2.01,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'DateTime-Format-Genealogy-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/DateTime-Format-Genealogy.git',
				web => 'https://github.com/nigelhorne/DateTime-Format-Genealogy',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Genealogy',
				web => 'https://github.com/nigelhorne/DateTime-Format-Genealogy/issues',
				url => 'https://github.com/nigelhorne/DateTime-Format-Genealogy/issues',
				mailto => 'bug-DateTime-Format-Genealogy@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
