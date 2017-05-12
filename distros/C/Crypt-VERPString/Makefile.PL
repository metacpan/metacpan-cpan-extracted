use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Crypt::VERPString',
    AUTHOR              => 'dorian taylor <dorian@cpan.org>',
    VERSION_FROM        => 'lib/Crypt/VERPString.pm',
    ABSTRACT_FROM       => 'lib/Crypt/VERPString.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Crypt::CBC'        => 0,
        'Crypt::Blowfish'   => 0,
        'MIME::Base32'      => 0,
        'Test::More'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-VERPString-*' },
);
