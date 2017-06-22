use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cuckoo::Filter',
    AUTHOR              => 'Kenji Doi <kend@cpan.org>',
    VERSION_FROM        => 'lib/Cuckoo/Filter.pm',
    ABSTRACT_FROM       => 'lib/Cuckoo/Filter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cuckoo-Filter-*' },
);
