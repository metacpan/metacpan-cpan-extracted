use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Config::Options",
               VERSION_FROM => "lib/Config/Options.pm",
               ABSTRACT_FROM => "lib/Config/Options.pm",
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
			   PREREQ_PM	=> { 'Data::Dumper' => 2.0,
			   					 'Test::More' => 0,
							     'Scalar::Util' => 0,
							 },
             );
