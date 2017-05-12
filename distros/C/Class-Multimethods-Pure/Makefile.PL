use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME           => 'Class::Multimethods::Pure',
    VERSION_FROM   => 'lib/Class/Multimethods/Pure.pm', 
    PREREQ_PM      => { }, 
    ABSTRACT_FROM  => 'lib/Class/Multimethods/Pure.pm',
    AUTHOR         => 'Luke Palmer <lrpalmer@gmail.com>',
);
