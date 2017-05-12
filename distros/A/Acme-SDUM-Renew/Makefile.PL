use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::SDUM::Renew',
    AUTHOR              => 'Ruben Fonseca <root@cpan.org>',
    VERSION_FROM        => 'lib/Acme/SDUM/Renew.pm',
    ABSTRACT_FROM       => 'lib/Acme/SDUM/Renew.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 2.033,
        'HTTP::Cookies'  => 1.39,
        'HTML::Form'     => 1.054,
        'File::Temp'     => 0.17,
        'Mail::Sender'   => '0.8.13',
        'Carp'           => 1.04,
        'Crypt::SSLeay'  => 0.53,
    },
    EXE_FILES           => [ 'lib/sdum_renew' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-SDUM-Renew-*' },
);
