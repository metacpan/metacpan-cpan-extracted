use ExtUtils::MakeMaker;

WriteMakefile(
     NAME          => 'DateTime::Format::DB2',
     VERSION_FROM  => 'lib/DateTime/Format/DB2.pm',
     PREREQ_PM     => { 'DateTime'                   => 0,
                        'DateTime::Format::Builder'  => 0,
                    },
);
