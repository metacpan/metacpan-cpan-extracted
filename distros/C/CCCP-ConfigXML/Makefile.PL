use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CCCP::ConfigXML',
    VERSION_FROM      => 'lib/CCCP/ConfigXML.pm',
    PREREQ_PM         => {
        'XML::Bare'             => 0,
        'Hash::Merge::Simple'   => 0,
        'namespace::autoclean'  => 0
    },
    ($] >= 5.005 ? (AUTHOR  => 'mr.Rico') : ()),
);
