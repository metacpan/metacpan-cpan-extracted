use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::CaptureIO',
    VERSION_FROM      => 'CaptureIO.pm', # finds $VERSION
    PREREQ_PM         => {
                          "Digest::SHA1" => 2.1,
                          "Storable"     => 2.14,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'CaptureIO.pm', # retrieve abstract from module
       AUTHOR         => 'emperor.kurt@gmail') : ()),
);
