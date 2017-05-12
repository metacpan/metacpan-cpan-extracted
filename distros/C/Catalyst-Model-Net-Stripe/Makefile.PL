use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Catalyst::Model::Net::Stripe',
    AUTHOR           => q{Adam Hopkins <srchulo@cpan.org>},
    VERSION_FROM     => 'lib/Catalyst/Model/Net/Stripe.pm',
    ABSTRACT_FROM    => 'lib/Catalyst/Model/Net/Stripe.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::Stripe' => 0,
        'Moose' => 0,
        'Carp' => 0,
        'Catalyst::Model' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Model-Net-Stripe-*' },
);
