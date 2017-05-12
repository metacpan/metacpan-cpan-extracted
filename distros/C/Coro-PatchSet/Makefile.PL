use 5.005000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'Coro::PatchSet',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/Coro/PatchSet.pm',
	PREREQ_PM         => { Coro => 1 },
	BUILD_REQUIRES    => {
		'Test::More' => 0.88
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-Coro-PatchSet'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/Coro/PatchSet.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
