use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => "DBIx::Struct",
	AUTHOR           => "Anton Petrusevich",
	VERSION          => "0.49",
	INSTALLDIRS      => 'site',
	LICENSE          => "artistic_2",
	MIN_PERL_VERSION => "5.014000",
	META_MERGE       => {
		"meta-spec" => {version => 2},
		resources   => {
			bugtracker => {web => 'https://github.com/jef-sure/dbix-struct-github/issues'},
			repository => {
				type => 'git',
				url  => 'https://github.com/jef-sure/dbix-struct-github.git',
				web  => 'https://github.com/jef-sure/dbix-struct-github',
			},
		},
	},
	PREREQ_PM => {
		'DBIx::Connector' => "0.52",
		'Digest::MD5'     => 0,
		'JSON'            => 0,
		'Scalar::Util'    => 0,
		'SQL::Abstract'   => 0,
	},
	TEST_REQUIRES => {'Test::More' => 0},
	test          => {TESTS        => "t/*.t"},
	dist          => {
		DIST_DEFAULT => 'all tardist',
		COMPRESS     => 'gzip -vf',
		SUFFIX       => '.gz',
	},
	clean     => {FILES => '*~',},
	realclean => {FILES => '*~',},
);
