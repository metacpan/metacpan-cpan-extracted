use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Algorithm::Bertsekas',
	AUTHOR            => 'Claudio Fernandes de Souza Rodrigues <claudiofsr@yahoo.com>',
	ABSTRACT          => 'auction algorithm for the assignment problem',
    VERSION_FROM      => 'lib/Algorithm/Bertsekas.pm',     # finds $VERSION
	LICENSE           => 'perl',
    PL_FILES          => {},
    PREREQ_PM         => {},
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Algorithm-Bertsekas-*' },
);
