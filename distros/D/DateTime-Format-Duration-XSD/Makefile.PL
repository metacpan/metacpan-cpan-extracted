use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'DateTime::Format::Duration::XSD',
    VERSION_FROM      => 'lib/DateTime/Format/Duration/XSD.pm',
    PREREQ_PM         => {
        'Test::More'                    => 0,
        'DateTime'                      => 0.30,
        'DateTime::Format::Duration'    => 1.03,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/DateTime/Format/Duration/XSD.pm',
       AUTHOR         => 'Smal D A <mialinx@gmail.com>') : ()),
);
