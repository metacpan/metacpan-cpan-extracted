use ExtUtils::MakeMaker;
WriteMakefile(
		NAME         => 'Bundle::Colloquy::BotBot2',
		VERSION_FROM => 'BotBot2.pm',
		'dist' => {
				COMPRESS => 'gzip -9f',
				SUFFIX   => '.gz', 
				DIST_DEFAULT => 'all tardist',
		},
	);
