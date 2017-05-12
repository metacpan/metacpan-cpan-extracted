use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBD::MVS_FTPSQL',
    AUTHOR              => 'Clemente Biondo <clemente.biondo@gmail.com>',
    VERSION_FROM        => 'lib/DBD/MVS_FTPSQL.pm', # finds $VERSION
    ABSTRACT_FROM       => 'lib/DBD/MVS_FTPSQL.pm', # retrieve abstract from module
    PL_FILES            => {},
    PREREQ_PM => {
        'DBI'         => 0,        
        'Net::FTP'    => 0,
        'IO::File'    => 0,        
        'Carp'        => 0,        
        'Test::More'  => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBD-MVS_FTPSQL-*' },
);
