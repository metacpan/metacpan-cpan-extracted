use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Apache::AuthPOP3',
    AUTHOR              => 'Sherwin Daganato <sherwin@cpan.org>',
    VERSION_FROM        => 'lib/Apache/AuthPOP3.pm',
    ABSTRACT_FROM       => 'lib/Apache/AuthPOP3.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Net::POP3'     => 0,
        'Cache::Cache'  => 0,
        'Digest::SHA1'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Apache-AuthPOP3-*' },
);
