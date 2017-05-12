use 5.006000;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::ProxyHunter::Model::Schema::SQLite',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/App/ProxyHunter/Model/Schema/SQLite.pm',
	PREREQ_PM         => {
		App::ProxyHunter:: => 0.01,
		DBD::SQLite::      => 0
	},
	BUILD_REQUIRES     => { 'Test::More' => 0.88 },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => {
		resources => {repository => 'https://github.com/olegwtf/p5-App-ProxyHunter-Model-Schema-SQLite'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/App/ProxyHunter/Model/Schema/SQLite.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
