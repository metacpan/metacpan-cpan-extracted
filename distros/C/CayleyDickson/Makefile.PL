use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CayleyDickson',
    VERSION_FROM      => 'lib/CayleyDickson.pm', # finds $VERSION
    PREREQ_PM         => {
        overload       => 0,
        'Data::Dumper' => 0,
    },
    test => {
        TESTS => 't/*.t'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CayleyDickson.pm', # retrieve abstract from module
       AUTHOR         => 'Jeff Anderson <truejeffanderson@gmail.com>') : ()),
);
