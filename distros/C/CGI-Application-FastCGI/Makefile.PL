use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Application::FastCGI',
    VERSION_FROM      => 'lib/CGI/Application/FastCGI.pm', # finds $VERSION
    PREREQ_PM         => {
		CGI::Application => 3.0,
		FCGI => 0.60,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/FastCGI.pm', # retrieve abstract from module
       AUTHOR         => 'Naoya Ito <naoya@naoya.dyndns.org>') : ()),
);
