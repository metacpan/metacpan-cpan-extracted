use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::Eparam',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/Eparam.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/Eparam.pm', # retrieve abstract from module
       AUTHOR         => 'Shinichiro Aska <askadna@gmail.com>') : ()),
);
