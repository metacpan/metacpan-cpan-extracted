use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'DateTime::Format::Text',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/DateTime/Format/Text.pm',
	ABSTRACT_FROM	=> 'lib/DateTime/Format/Text.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Class::Simple' => 0,
		'Test::Deep' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Pod' => 0,
		'Test::Pod::LinkCheck' => 0,
		'Test::Pod::Spelling::CommonMistakes' => 0,
		'Test::Spelling' => 0,
		'strict' => 0,
		'warnings' => 0,
		'WWW::RT::CPAN' => 0
	},
	PREREQ_PM => {
		'Carp' => 0,
		'DateTime' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'DateTime-Format-Text-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/DateTime-Format-Text.git',
			web => 'https://github.com/nigelhorne/DateTime-Format-Text',
			},
			bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-Text',
				mailto => 'bug-DateTime-Format-Text@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
