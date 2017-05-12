use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Apache::Scriptor::Simple',
    'VERSION_FROM'  => 'Simple.pm', # finds $VERSION
    'PREREQ_PM'   => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'The simplest way to activate Apache::Scriptor', # retrieve abstract from module
       AUTHOR    => 'Dmitry Koterov <koterov at cpan dot org>') : ()),
);
