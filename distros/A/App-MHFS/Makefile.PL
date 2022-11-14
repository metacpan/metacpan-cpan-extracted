use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

my %WriteMakefileArgs = (
    NAME             => 'App::MHFS',
    AUTHOR           => "Gavin Hayes <gahayes\@cpan.org>",
    VERSION_FROM     => 'lib/App/MHFS.pm',
    ABSTRACT_FROM    => 'lib/App/MHFS.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        "File::ShareDir::Install" => "0.13"
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        "URI::Escape" => "5.09",
        "HTML::Template" => "2.97",
        "File::ShareDir" => 0,
    },
    EXE_FILES => ['bin/mhfs'],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-MHFS-*' },
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
        prereqs => {
            runtime => {
                recommends => {
                    'MHFS::XS' => '0',
                    'Alien::Tar::Size' => '0'
                }
            }
        }
    },
);

# Perl CORE Time::HiRes is usually good enough, but Windows support was added recently
if( ! (eval "use Time::HiRes qw( clock_gettime ); 1")) {
    $WriteMakefileArgs{PREREQ_PM}{'Time::HiRes'} = '1.9764';
}

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
package
MY;
use File::ShareDir::Install qw(postamble);
}
