use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Data::FetchPath',
    AUTHOR        => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    VERSION_FROM  => 'lib/Data/FetchPath.pm',
    ABSTRACT_FROM => 'lib/Data/FetchPath.pm',
    PL_FILES      => {},
    PREREQ_PM     => { 'Test::Most' => 0, },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-FetchPath-*' },
);
