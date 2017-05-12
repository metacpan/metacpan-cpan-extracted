use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::LeetSpeak',
    AUTHOR              => 'Jordan M. Adler <jmadler@cpan.org>',
    VERSION_FROM        => 'lib/Acme/LeetSpeak.pm',
    ABSTRACT_FROM       => 'lib/Acme/LeetSpeak.pm',
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-LeetSpeak-*' },
);
