use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Asm::X86',
    AUTHOR              => 'Bogdan Drozdowski <bogdandr@op.pl>',
    VERSION_FROM        => 'lib/Asm/X86.pm',
    ABSTRACT_FROM       => 'lib/Asm/X86.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Asm-X86-*' },
);
