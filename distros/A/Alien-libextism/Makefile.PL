use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;
 
my $abmm = Alien::Build::MM->new;

my %WriteMakefileArgs = (
$abmm->mm_args (
    DISTNAME         => 'Alien-libextism',
    NAME             => 'Alien::libextism',
    AUTHOR           => 'Extism Authors <extism@cpan.org>',
    VERSION_FROM     => 'lib/Alien/libextism.pm',
    ABSTRACT_FROM    => 'lib/Alien/libextism.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Sort::Versions' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    #PREREQ_PM => {
    #},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Alien-libextism-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/extism/perl-sdk.git',
                web  => 'https://github.com/extism/perl-sdk',
            },
            bugtracker => {
                web => 'https://github.com/extism/perl-sdk/issues'
            },
            homepage   => 'https://extism.org',
        },
    },
));

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
sub MY::postamble {
  $abmm->mm_postamble;
}