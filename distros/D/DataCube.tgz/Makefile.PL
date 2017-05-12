use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'DataCube',
    VERSION_FROM      => 'lib/DataCube.pm',
    PREREQ_PM         => {
        'Test::Most' => '0',
    },
    ($] >= 5.005 ? (
        ABSTRACT_FROM  => 'lib/DataCube.pm', 
       AUTHOR         => 'David Williams <david@namimedia.com>') : ()),
);
