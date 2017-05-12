use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::Cache::File',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/Cache/File.pm', # finds $VERSION
    PREREQ_PM         => {'Cache::File' => '2.04'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/Cache/File.pm', # retrieve abstract from module
       AUTHOR         => 'Job van Achterberg <job@>') : ()),
);
