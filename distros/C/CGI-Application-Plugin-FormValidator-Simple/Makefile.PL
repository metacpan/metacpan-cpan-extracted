use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::FormValidator::Simple',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/FormValidator/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
      CGI::Application      => '3.31',
      FormValidator::Simple => '0.03',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/FormValidator/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Gosuke Miyashita <gosukenator@gmail.com>') : ()),
);
