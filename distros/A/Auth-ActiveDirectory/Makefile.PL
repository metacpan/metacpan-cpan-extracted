use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Auth::ActiveDirectory',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Auth/ActiveDirectory.pm',
    ABSTRACT_FROM      => 'lib/Auth/ActiveDirectory.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Net::LDAP' => 0,
    },
    TEST_REQUIRES => {
        'Pod::Coverage::TrustPod' => 0,
        'Pod::Usage'              => 0,
        'Test::CheckManifest'     => 0,
        'Test::Pod::Coverage'     => 0,
        'Test::Requires'          => 0,
        'Test::Spelling'          => 0,
        'Test::Net::LDAP'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Auth-ActiveDirectory-*' },
);
