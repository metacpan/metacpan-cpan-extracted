use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;
use Config;
use File::Spec;

# test we have headers as an OS check

## Build the command
my @scmd = ($Config{cc}, '-D_GNU_SOURCE');
push @scmd, '-include', $_ foreach ('errno.h', 'dlfcn.h');
push @scmd, '-E', '-';

## Redirect STDIN and STDOUT to /dev/null or equivalent (stdin is unused though an input file must be provided, it dumps the preprocessor input to STDOUT)
open(my $oldin, "<&STDIN") or die "Can't dup STDIN:";
open(my $oldout, '>&STDOUT') or die('cant dup STDOUT');
open(my $devnull, '+<', File::Spec->devnull());
open(STDOUT, '>&', $devnull) or die('error redirecting stdout');
open(STDIN, '<&', $devnull) or die('error redirecting stdin ');

## finally run the command
system(@scmd) == 0 or die('OS unsupported');

## Restore STDIN and STDOUT
open(STDOUT, '>&', $oldout) or die('error restoring stdout');
open(STDIN, '<&', $oldin) or die('error restoring stdin');

my $abmm = Alien::Build::MM->new;
my %WriteMakefileArgs = (
    $abmm->mm_args (
    DISTNAME         => 'Alien-Tar-Size',
    NAME             => 'Alien::Tar::Size',
    AUTHOR           => "Gavin Hayes <gahayes\@cpan.org>",
    VERSION_FROM     => 'lib/Alien/Tar/Size.pm',
    ABSTRACT_FROM    => 'lib/Alien/Tar/Size.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'Alien::Build::MM' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    BUILD_REQUIRES => {
        'Alien::Build::MM' => 0,
    },
    PREREQ_PM => {
        'Alien::Base' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Alien-Tar-Size-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/G4Vi/MHFS.git',
                web  => 'https://github.com/G4Vi/MHFS',
            },
            bugtracker => {
                web => 'https://github.com/G4Vi/MHFS/issues'
            },
            homepage   => 'https://github.com/G4Vi/MHFS',
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