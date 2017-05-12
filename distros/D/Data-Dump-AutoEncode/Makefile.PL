use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'Data::Dump::AutoEncode',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Data/Dump/AutoEncode.pm',
    ABSTRACT_FROM => 'lib/Data/Dump/AutoEncode.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Data-Dump-AutoEncode',
        },
    },
);
