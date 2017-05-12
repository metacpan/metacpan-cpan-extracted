use ExtUtils::MakeMaker;

    WriteMakefile(
        NAME            => 'CGI::Session::BitBucket',
        VERSION_FROM    => 'lib/CGI/Session/BitBucket.pm',
        ABSTRACT_FROM   => 'lib/CGI/Session/BitBucket.pm',
		MAKEFILE => 'Makefile',
		PL_FILES => {},
		PREREQ_PM => { 'CGI::Session' => '0' }
    );

