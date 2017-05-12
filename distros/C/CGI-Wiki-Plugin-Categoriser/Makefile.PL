use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "CGI::Wiki::Plugin::Categoriser",
               VERSION_FROM => "lib/CGI/Wiki/Plugin/Categoriser.pm",
	       PREREQ_PM    => { 'CGI::Wiki' => 0.36, # for Plugin base class
			         'Test::More' => 0,
				 'Carp' => 0
                               },
               clean => { FILES => "t/sqlite-test.db t/sii-db-file-test.db" }
	      );

