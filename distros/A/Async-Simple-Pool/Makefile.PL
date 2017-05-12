use 5.10.0;

use Modern::Perl;
use Module::Metadata;
use ExtUtils::MakeMaker;

if ( $^O =~ /^(dos|os2|MSWin32|NetWare)$/ ) {
    die 'OS unsupported';
};

WriteMakefile(
    NAME             => 'Async::Simple::Pool',
    AUTHOR           => q{ANTONC <antonc@cpan.org>},
    VERSION_FROM     => 'lib/Async/Simple/Pool.pm',
    ABSTRACT_FROM    => 'lib/Async/Simple/Pool.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'Modern::Perl'        => 0,
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => 0,
        'Modern::Perl'        => 0,
        'Test::Spec'          => 0,
        'Pod::Coverage'       => 0,
        'POSIX'               => 0,
        'Test::CheckManifest' => 0,
        'Test::Exception'     => 0,
        'Test::Pod::Coverage' => 0,
        'Test::Pod'           => 0,
        'Time::HiRes'         => 0,
        'Module::Metadata'    => 0,
    },
    PREREQ_PM => {
        'Class::Load'          => 0,
        'Clone'                => 0,
        'Data::Dumper'         => 0,
        'Data::Serializer'     => 0,
        'Modern::Perl'         => 0,
        'Moose'                => 0,
        'namespace::autoclean' => 0,
        'Time::HiRes'          => 0,
    },
    META_ADD => {
        provides => Module::Metadata->provides(version => '1.4', dir => 'lib'),
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Async-Simple-Pool-*' },
);
