use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Phrasebook::Loader::ApacheFormat',
    VERSION_FROM      => 'lib/Data/Phrasebook/Loader/ApacheFormat.pm',
    PREREQ_PM         => {
                          'Test::More'           => 0,
                          'Config::ApacheFormat' => 1.2,
                          'Data::Phrasebook'     => 0.21,
                         },
    ABSTRACT_FROM  => 'lib/Data/Phrasebook/Loader/ApacheFormat.pm',
    AUTHOR         => 'Sam <sam@tregar.com>',
);
