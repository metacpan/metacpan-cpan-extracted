    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Acme-VerySign',
       'VERSION' => '1.00',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Test::More' => '0',
			'Symbol::Approx::Sub' => '2.00',

		      },
      );
