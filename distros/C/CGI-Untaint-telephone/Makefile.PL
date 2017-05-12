use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'CGI::Untaint::telephone',
    VERSION_FROM   => 'lib/CGI/Untaint/telephone.pm',
    PREREQ_PM      => {
                        'CGI::Untaint' => 1.26
                      },
    AUTHOR         => 'Toby Corkindale <cpan@corkindale.net>',
    ABSTRACT => 'CGI::Untaint plugin to untaint telephone numbers'
);
