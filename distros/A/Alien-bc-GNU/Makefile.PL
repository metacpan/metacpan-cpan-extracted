use strict;
use warnings;

use Alien::Build::MM;
use ExtUtils::MakeMaker 6.76;

my %WriteMakefileArgs = (
	'ABSTRACT' => 'Find or download and install GNU bc.',
	'AUTHOR' => "Michal Josef \x{160}pa\x{10d}ek <skim\@cpan.org>",
	'BUILD_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'Alien::ed::GNU' => 0,
		'Alien::Texinfo' => 0,
		'ExtUtils::MakeMaker' => '6.76',
	},
	'CONFIGURE_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'ExtUtils::MakeMaker' => '6.76',
	},
	'DISTNAME' => 'Alien-bc-GNU',
	'LICENSE' => 'bsd',
	'META_MERGE' => {
		'resources' => {
			'bugtracker' => 'https://github.com/michal-josef-spacek/Alien-bc-GNU/issues',
			'repository' => 'https://github.com/michal-josef-spacek/Alien-bc-GNU',
		},
	},
	'NAME' => 'Alien::bc::GNU',
	'PREREQ_PM' => {
		'Alien::Base' => 0,
		'Path::Tiny' => 0,
		'parent' => 0,
		'strict' => 0,
		'warnings' => 0,
	},
	( ! exists $ENV{CI} ? ( 'SIGN' => 1 ) : () ),
	'TEST_REQUIRES' => {
		'Test::Alien' => 0,
		'Test::Alien::Diag' => 2.67,
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
	},
	'VERSION' => '0.03',
	'test' => {
		'RECURSIVE_TEST_FILES' => 1,
	}
);

my $abmm = Alien::Build::MM->new;
WriteMakefile($abmm->mm_args(%WriteMakefileArgs));

sub MY::postamble {
	$abmm->mm_postamble(@_);
}
 
sub MY::install {
	$abmm->can('mm_install')
		? $abmm->mm_install(@_)
		: shift->SUPER::install(@_);
}
