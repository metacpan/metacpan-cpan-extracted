use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Serializer',
    AUTHOR              => 'Nilson Santos Figueiredo Junior <nilsonsfj@cpan.org>',
    VERSION_FROM        => 'lib/Class/Serializer.pm',
    ABSTRACT_FROM       => 'lib/Class/Serializer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'           => 0,
		'Data::Dump::Streamer' => 0,
		'B::Deparse'           => 0,
		'File::Path'           => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Class-Serializer-*' },
);
