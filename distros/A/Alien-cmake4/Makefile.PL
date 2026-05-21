use strict;
use warnings;

use Alien::Build::MM;
use ExtUtils::MakeMaker 6.76;

my %WriteMakefileArgs = (
	'ABSTRACT' => 'Find or download and install cmake4',
	'AUTHOR' => "Michal Josef \x{160}pa\x{10d}ek <skim\@cpan.org>",
	'BUILD_REQUIRES' => {
		'Archive::Tar' => 0, # share
		'Config' => 0,
		'File::Spec' => 0,
		'HTTP::Tiny' => 0.044, # share
		'IO::Socket::SSL' => 1.56, # share
		'IO::Zlib' => 0, # share
		'Mojo::DOM' => 0, # share
		'Mojolicious' => 7.00, # share
		'Mozilla::CA' => 0, # share
		'Net::SSLeay' => 1.49, # share
		'Sort::Versions' => 0, # share
		'URI' => 0, # share
		'URI::Escape' => 0, # share
		'version' => 0,
	},
	'CONFIGURE_REQUIRES' => {
		'Alien::Build::MM' => '0.32',
		'Alien::Build::Plugin::Build::Autoconf' => 0,
		'Alien::Build::Plugin::Probe::CommandLine' => 0,
		'ExtUtils::MakeMaker' => '6.76',
	},
	'DISTNAME' => 'Alien-cmake4',
	'LICENSE' => 'perl',
	'MIN_PERL_VERSION' => '5.008001',
	'META_MERGE' => {
		'resources' => {
			'bugtracker' => 'https://github.com/michal-josef-spacek/Alien-cmake4/issues',
			'repository' => 'https://github.com/michal-josef-spacek/Alien-cmake4',
		},
	},
	'NAME' => 'Alien::cmake4',
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
		'Test::Alien::Diag' => 0,
		'Test::More' => 0,
		'Test::NoWarnings' => 0,
	},
	'VERSION' => '0.04',
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
