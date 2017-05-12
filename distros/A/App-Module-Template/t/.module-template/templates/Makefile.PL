use strict;
use warnings FATAL => 'all';

use [% min_perl_version %];

use ExtUtils::MakeMaker [% eumm_version %];

my %WriteMakefileArgs = (
    NAME                  => '[% module %]',
    AUTHOR                => '[% author %] <[% email %]>',
    VERSION_FROM          => '[% module_path %]',
    ABSTRACT_FROM         => '[% module_path %]',
    LICENSE               => '[% license_type %]',
    DISTNAME              => '[% dist %]',
    MIN_PERL_VERSION      => [% min_perl_version %],
    BUILD_REQUIRES        => {
        'ExtUtils::MakeMaker' => [% eumm_version %],
    },
    CONFIGURE_REQUIRES    => {
        'ExtUtils::MakeMaker' => [% eumm_version %],
    },
    PREREQ_PM             => {
        'Carp'            => 0,
        'POSIX'           => 0,
        #'Some::Module' => 1.23,
    },
    TEST_REQUIRES         => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },
    test                  => { "TESTS" => "t/*.t", },
    dist                  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                 => { FILES => '-*' },
);

my %FallbackPrereqs = (
    'Carp'                => 0,
    'POSIX'               => 0,
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakeFile(%WriteMakefileArgs);
