    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Attempt',
       'VERSION' => '1.01',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Test::More' => '0',
			'Test::Exception' => '0',
			'Sub::Uplevel' => '0.07',

		      },
      );
