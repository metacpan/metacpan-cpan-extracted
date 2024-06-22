use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'Class::Simple::Cached',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Class/Simple/Cached.pm',
	ABSTRACT_FROM   => 'lib/Class/Simple/Cached.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	PREREQ_PM => {
		'Carp' => 0,
		'Class::Simple' => 0,
	}, TEST_REQUIRES => {
		'CHI' => 0,
		'Class::Simple' => 0,
		'File::Spec' => 0,
		'Test::Carp' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
		'Test::NoWarnings' => 0,
		'Test::Requires' => 0,
		# 'Test::Kwalitee' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Class-Simple-Cached-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Class-Simple-Cached.git',
				web => 'https://github.com/nigelhorne/Class-Simple-Cached',
				repository => 'https://github.com/nigelhorne/Class-Simple-Cached',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Simple-Cached',
				mailto => 'bug-Class-Simple-Cached@rt.cpan.org',
				web => 'https://github.com/nigelhorne/Class-Simple-Cached/issues',
				url => 'https://github.com/nigelhorne/Class-Simple-Cached/issues',
			}
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
