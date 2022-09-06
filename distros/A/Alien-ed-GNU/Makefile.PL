use strict;
use warnings;

use Alien::Build::MM;
use ExtUtils::MakeMaker 6.76;

my %WriteMakefileArgs = (
	'ABSTRACT' => 'Find or download and install GNU ed.',
	'AUTHOR' => "Michal Josef \x{160}pa\x{10d}ek <skim\@cpan.org>",
	'BUILD_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'ExtUtils::MakeMaker' => '6.76',
	},
	'CONFIGURE_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'Alien::Build::Plugin::Extract::Libarchive' => 0,
		'ExtUtils::MakeMaker' => '6.76',
	},
	'DISTNAME' => 'Alien-ed-GNU',
	'LICENSE' => 'bsd',
	'META_MERGE' => {
		'resources' => {
			'bugtracker' => 'https://github.com/michal-josef-spacek/Alien-ed-GNU/issues',
			'repository' => 'https://github.com/michal-josef-spacek/Alien-ed-GNU',
		},
	},
	'NAME' => 'Alien::ed::GNU',
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
	'VERSION' => '0.02',
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
