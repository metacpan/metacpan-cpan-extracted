use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		      => 'Apache::Session::Lazy',
    'VERSION_FROM'	=> 'Lazy.pm', # finds $VERSION
    'PREREQ_PM'     => {
       'Apache::Session' => '0', # Module::Name => 1.1
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Lazy.pm', # retrieve abstract from module
       AUTHOR     => 'Gyan Kapur <gkapur@inboxusa.com>') : ()),
);