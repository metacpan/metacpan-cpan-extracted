use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::CGI::Untaint',
    VERSION_FROM      => 'lib/Catalyst/Plugin/CGI/Untaint.pm', # finds $VERSION
    PREREQ_PM         => {
                           'Catalyst' => 5.50,
                           'CGI::Untaint' => 1.20,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/CGI/Untaint.pm', # retrieve abstract from module
       AUTHOR         => 'Toby Corkindale <cpan@corkindale.net>') : ()),
);
