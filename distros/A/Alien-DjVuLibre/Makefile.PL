use strict;
use warnings;

use Alien::Build::MM;
use ExtUtils::MakeMaker 6.76;

my %WriteMakefileArgs = (
	'ABSTRACT' => 'Find or download and install DjVuLibre',
	'AUTHOR' => "Michal Josef \x{160}pa\x{10d}ek <skim\@cpan.org>",
	'BUILD_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'ExtUtils::MakeMaker' => '6.76',
		'ExtUtils::CppGuess' => 0,
	},
	'CONFIGURE_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'Alien::Build::Plugin::PkgConfig::Negotiate' => 0,
		'ExtUtils::MakeMaker' => '6.76',
		'File::Which' => '0',
	},
	'DISTNAME' => 'Alien-DjVuLibre',
	'LICENSE' => 'bsd',
	'META_MERGE' => {
		'resources' => {
			'bugtracker' => 'https://github.com/michal-josef-spacek/Alien-DjVuLibre/issues',
			'repository' => 'https://github.com/michal-josef-spacek/Alien-DjVuLibre',
		},
	},
	'NAME' => 'Alien::DjVuLibre',
	'PREREQ_PM' => {
		'Alien::Base' => 0,
		'parent' => 0,
		'strict' => 0,
		'warnings' => 0,
	},
	( ! exists $ENV{CI} ? ( 'SIGN' => 1 ) : () ),
	'TEST_REQUIRES' => {
		'Test::Alien' => 0,
		'Test::Alien::Diag' => 0,
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
	},
	'VERSION' => '0.05',
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
