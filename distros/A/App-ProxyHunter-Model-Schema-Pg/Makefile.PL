use 5.006000;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::ProxyHunter::Model::Schema::Pg',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/App/ProxyHunter/Model/Schema/Pg.pm',
	PREREQ_PM         => {
		App::ProxyHunter::     => 0.01,
		DBD::Pg::              => 0.4,
		DateTime::Format::Pg:: => 0
	},
	BUILD_REQUIRES     => { 'Test::More' => 0.88 },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => {
		resources => {repository => 'https://github.com/olegwtf/p5-App-ProxyHunter-Model-Schema-Pg'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/App/ProxyHunter/Model/Schema/Pg.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
