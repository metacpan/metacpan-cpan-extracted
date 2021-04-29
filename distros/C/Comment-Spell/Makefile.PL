use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
	NAME		=> 'Comment::Spell',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Comment/Spell.pm',
	ABSTRACT_FROM	   => 'lib/Comment/Spell.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],   # e.g., '-lm'
	'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING'
	'INC' => '',     # e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Test::More' => 0,
	}, PREREQ_PM => {
		'Carp' => 0,
		'Moo' => 0,
		'Pod::Wordlist' => 1.07,
		'PPI' => 0,
		'Path::Tiny' => 0,
		'IO::Handle' => 0,
		'IO::Scalar' => 0,
		'Text::Wrap' => 0,
	},
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean		=> { FILES => 'Comment-Spell-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Comment-Spell.git',
				web => 'https://github.com/nigelhorne/Comment-Spell',
				repository => 'https://github.com/nigelhorne/Comment-Spell',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Comment-Spell',
				web => 'https://github.com/nigelhorne/Comment-Spell/issues',
				url => 'https://github.com/nigelhorne/Comment-Spell/issues',
				mailto => 'bug-Comment-Spell@rt.cpan.org'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
