use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'Class::Simple::Readonly::Cached',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Class/Simple/Readonly/Cached.pm',
	ABSTRACT_FROM   => 'lib/Class/Simple/Readonly/Cached.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'CHI' => 0,
		'Test::Carp' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Requires' => 0,
		# 'Test::Kwalitee' => 0,
	},
	PREREQ_PM => {
		'Carp' => 0,
		'Class::Simple' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Class-Simple-Readonly-Cached-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Class-Simple-Readonly-Cached.git',
				web => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached',
				repository => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached',
			},
			bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Simple-Readonly-Cached',
				# mailto => 'bug-Class-Simple-Readonly-Cached@rt.cpan.org'
				web => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues',
				url => 'https://github.com/nigelhorne/Class-Simple-Readonly-Cached/issues',
			}
		
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
