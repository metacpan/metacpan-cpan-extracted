use ExtUtils::MakeMaker;

    WriteMakefile(
        NAME            => 'CGI::Session::Driver::bitbucket',
        VERSION_FROM    => 'lib/CGI/Session/Driver/bitbucket.pm',
        ABSTRACT_FROM   => 'lib/CGI/Session/Driver/bitbucket.pm',
		MAKEFILE => 'Makefile',
		PL_FILES => {},
		PREREQ_PM => { 'CGI::Session' => '4.00' }
    );

