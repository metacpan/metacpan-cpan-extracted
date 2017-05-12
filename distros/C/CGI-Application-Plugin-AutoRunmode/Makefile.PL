use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::AutoRunmode',
    VERSION_FROM      => 'AutoRunmode.pm', # finds $VERSION
    PREREQ_PM         => {
		'CGI::Application' => 3,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'AutoRunmode.pm', # retrieve abstract from module
       AUTHOR         => 'Thilo Planz <thilo@cpan.org>') : ()),
);
