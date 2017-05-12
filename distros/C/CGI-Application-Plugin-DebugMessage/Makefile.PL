use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::DebugMessage',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/DebugMessage.pm', # finds $VERSION
    PREREQ_PM         => {
        CGI::Application => 3.21,
        Test::More     => 0.32,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/DebugMessage.pm', # retrieve abstract from module
       AUTHOR         => 'Makio Tsukamoto <tsukamoto@gmail.com>') : ()),
);
