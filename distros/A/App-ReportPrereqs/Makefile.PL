use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    ABSTRACT           => 'report prerequisite versions',
    AUTHOR             => 'Sven Kirmess <sven.kirmess@kzone.ch>',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    DISTNAME  => 'App-ReportPrereqs',
    EXE_FILES => [
        'bin/report-prereqs',
    ],
    LICENSE          => 'open_source',
    MIN_PERL_VERSION => '5.006',
    NAME             => 'App::ReportPrereqs',
    PREREQ_PM        => {
        'CPAN::Meta'          => 0,
        'ExtUtils::MakeMaker' => 0,
        'File::Basename'      => 0,
        'Getopt::Long'        => 0,
        'HTTP::Tiny'          => '0.014',
        'List::Util'          => 0,
        'Module::CPANfile'    => 0,
        'Module::Path'        => 0,
        strict                => 0,
        version               => '0.77',
        warnings              => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        lib          => 0,
    },
    VERSION => '0.008',
    test    => {
        TESTS => 't/*.t',
    },
);

my %FallbackPrereqs = (
    'CPAN::Meta'          => 0,
    'ExtUtils::MakeMaker' => 0,
    'File::Basename'      => 0,
    'Getopt::Long'        => 0,
    'HTTP::Tiny'          => '0.014',
    'List::Util'          => 0,
    'Module::CPANfile'    => 0,
    'Module::Path'        => 0,
    'Test::More'          => '0.88',
    lib                   => 0,
    strict                => 0,
    version               => '0.77',
    warnings              => 0,
);

if ( $ENV{AUTOMATED_TESTING} || $ENV{EXTENDED_TESTING} ) {
    $WriteMakefileArgs{test}{TESTS} .= ' xt/*.t';
    _add_extended_test_requirements();
}

if ( !eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    delete $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{BUILD_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } ) {
    delete $WriteMakefileArgs{CONFIGURE_REQUIRES};
}

WriteMakefile(%WriteMakefileArgs);

sub test_requires {
    my ( $module, $version_or_range ) = @_;
    $WriteMakefileArgs{TEST_REQUIRES}{$module} = $FallbackPrereqs{$module} = $version_or_range;
    return;
}

sub _add_extended_test_requirements {
    test_requires( 'Capture::Tiny',    0 );
    test_requires( 'Cwd',              0 );
    test_requires( 'File::Spec',       0 );
    test_requires( 'Test::MockModule', '0.14' );
    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
