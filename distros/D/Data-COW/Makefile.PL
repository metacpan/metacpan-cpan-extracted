use 5.006001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Data::COW',
    VERSION_FROM      => 'lib/Data/COW.pm',
    PREREQ_PM         => { 'Scalar::Util' => 0 },
    ABSTRACT_FROM  => 'lib/Data/COW.pm', 
    AUTHOR         => 'Luke Palmer <fibonaci@localdomain>',
);
