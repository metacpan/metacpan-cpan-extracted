use ExtUtils::MakeMaker;

WriteMakefile( NAME         => "CGI::Wiki::Plugin::Locator::UK",
	       VERSION_FROM => "lib/CGI/Wiki/Plugin/Locator/UK.pm",
	       PREREQ_PM    => { 'CGI::Wiki' => 0.36, # for Plugin base class
                                 'Geography::NationalGrid' => 0,
                                 'Geography::NationalGrid::GB' => 0,
			         'Test::More' => 0,
				 'Carp' => 0
                               },
               clean => { FILES => "t/sqlite-test.db t/sii-db-file-test.db" }
	     );

