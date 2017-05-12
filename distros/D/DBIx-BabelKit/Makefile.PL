
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'DBIx::BabelKit',
    VERSION_FROM	=> 'BabelKit.pm',
    PREREQ_PM		=> { DBI => 0 },
    PM                  => { 'BabelKit.pm' => '$(INST_LIBDIR)/BabelKit.pm' },
    ($] >= 5.005 ?
        (ABSTRACT_FROM       => 'BabelKit.pm',
         AUTHOR              => 'John Gorman <jgorman@webbysoft.com>') : ()),
);
