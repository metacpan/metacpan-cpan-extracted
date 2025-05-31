use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Alien::PDFio',
    AUTHOR           => q{LNATION <email@lnation.org>},
    VERSION_FROM     => 'lib/Alien/PDFio.pm',
    ABSTRACT_FROM    => 'lib/Alien/PDFio.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    BUILD_REQUIRES  => {
        "Alien::Build"        => "0.32",
        "Alien::Build::MM"    => "0.32",
        "ExtUtils::MakeMaker" => "6.52"
    },
    CONFIGURE_REQUIRES => {
        "Alien::Build" => "0.32",
        "Alien::Build::MM"  => "0.32",
	'Alien::Build::Plugin::Download::GitHub' => "0.10",
	'ExtUtils::MakeMaker' => '0',
    },
    DISTNAME => "Alien-PDFio",
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Alien-PDFio-*' },
);

use Alien::Build::MM;
my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

{
    package MY;
    sub postamble {
        $abmm->mm_postamble(@_);
    }
    sub install {
        $abmm->can('mm_install')
          ? $abmm->mm_install(@_)
          : shift->SUPER::install(@_);
    }
}
