use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Inner',
    'VERSION_FROM'	=> 'lib/Class/Inner.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'META_MERGE'	=> {
        resources => {
            repository => 'http://github.com/arunbear/perl5-class-inner',
        },
    },
);
