use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => "DBIx::PgCoroAnyEvent",
	AUTHOR           => "Anton Petrusevich",
	VERSION          => "0.04",
	INSTALLDIRS      => 'site',
	LICENSE          => "artistic_2",
	MIN_PERL_VERSION => "5.014000",
	META_MERGE       => {
		"meta-spec" => {version => 2},
		resources   => {
			bugtracker => {web => 'https://github.com/jef-sure/dbd-pg-cae/issues'},
			repository => {
				type => 'git',
				url  => 'https://github.com/jef-sure/dbd-pg-cae.git',
				web  => 'https://github.com/jef-sure/dbd-pg-cae',
			},
		},
	},
	PREREQ_PM => {
		'DBD::Pg'        => "1.44",
		'Coro'           => 0,
		'AnyEvent'       => 0,
		'Coro::AnyEvent' => 0,
	},
	TEST_REQUIRES => {
		'Test::More'  => 0,
		'DBI'         => 0,
		'File::Temp'  => 0,
		'Time::HiRes' => 0,
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
