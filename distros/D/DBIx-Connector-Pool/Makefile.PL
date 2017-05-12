use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => "DBIx::Connector::Pool",
	AUTHOR           => "Anton Petrusevich",
	VERSION          => "0.02",
	INSTALLDIRS      => 'site',
	LICENSE          => "artistic_2",
	MIN_PERL_VERSION => "5.014000",
	META_MERGE       => {
		"meta-spec" => {version => 2},
		resources   => {
			bugtracker => {web => 'https://github.com/jef-sure/DBIx-Connector-Pool/issues'},
			repository => {
				type => 'git',
				url  => 'https://github.com/jef-sure/DBIx-Connector-Pool.git',
				web  => 'https://github.com/jef-sure/DBIx-Connector-Pool',
			},
		},
	},
	PREREQ_PM => {
		'DBIx::Connector' => 0,
		'Coro'            => 0,
		'AnyEvent'        => 0,
		'Coro::AnyEvent'  => 0,
		'Time::HiRes'     => 0,
	},
	TEST_REQUIRES => {
		'Test::More'           => 0,
		'File::Temp'           => 0,
		'DBIx::PgCoroAnyEvent' => "0.03",
	},
	test => {TESTS => "t/*.t"},
	dist => {
		DIST_DEFAULT => 'all tardist',
		COMPRESS     => 'gzip -vf',
		SUFFIX       => '.gz',
	},
	clean     => {FILES => '*~',},
	realclean => {FILES => '*~',},
);
