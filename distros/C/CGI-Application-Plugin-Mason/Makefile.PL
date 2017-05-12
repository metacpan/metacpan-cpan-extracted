use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::Mason',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/Mason.pm', # finds $VERSION
    PREREQ_PM         => { 
                          "CGI::Application"                => 4.05,
                          "CGI::Application::Plugin::Stash" => 0.01,
                          "HTML::Mason"                     => 1.35
                        }, # e.g., Module::Name => 1.1 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/Mason.pm', # retrieve abstract from module
       AUTHOR         => 'Akira Horimoto') : ()),
);
