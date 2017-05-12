use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::Session::Driver::chi',
    VERSION_FROM      => 'lib/CGI/Session/Driver/chi.pm', # finds $VERSION
    PREREQ_PM => {
        'CHI'                        => 0,
        'CGI::Session::ErrorHandler' => "4.0",
        'CGI::Session::Driver'       => "4.0",
      },    # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'A CGI::Session::Driver for CHI', # retrieve abstract from module
       AUTHOR         => 'James Rouzier <rouzier@gmail.com>') : ()),
);
