use 5.010;
use strict;
use warnings;
use version;

use ExtUtils::MakeMaker;


#  Bring in this MakeMaker plugin when available
#
eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1
};

#  Main Makefile.PL section
#
my $mm_ver=$ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver=eval($mm_ver);
    die $@ if $@;
}
my %WriteMakefile=(
    NAME                => 'ASPEER::MakeMaker::Markdown::Pod',
    DISTNAME            => 'ASPEER-MakeMaker-Markdown-Pod',
    VERSION_FROM        => 'lib/ASPEER/MakeMaker/Markdown/Pod.pm',
    ABSTRACT_FROM       => 'lib/ASPEER/MakeMaker/Markdown/Pod.pm',
    EXE_FILES           => [],
    LICENSE             => 'perl',
    AUTHOR              => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION    => '5.010',
    PREREQ_PM           =>  {
        'ASPEER::MakeMaker'     =>  '1.010',
        'Cwd'                   =>  0,
        'Digest::MD5'           =>  0,
        'Docbook::Convert'      =>  '1.010',
        'ExtUtils::Manifest'    =>  0,
        'Exporter'              =>  0,
        'File::Basename'        =>  0,
        'File::Spec'            =>  0,
        'Markdown::Pod::Embed'  =>  '1.010',
        'strict'                =>  0,
        'vars'                  =>  0,
        'warnings'              =>  0,
    },
    CONFIGURE_REQUIRES  =>  {
        'ExtUtils::MakeMaker'   =>  0,
        'version'               =>  0,
    },
    TEST_REQUIRES       =>  {
        'File::Path'            =>  0,
        'File::Temp'            =>  0,
        'Test::More'            =>  0,
    },
    META_MERGE => {
        x_authority     => 'cpan:ASPEER',
        'meta-spec'     => {
            version     => 2
        },
        resources       => {
            bugtracker  => {
                web     => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Pod/issues',
            },
            homepage    => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Pod',
            repository  => {
                type    => 'git',
                url     => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Pod.git',
                web     => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Pod'
            }
        }
    },
    depend              => {
        Makefile        => '$(VERSION_FROM)',
    },
    dist                => {
        COMPRESS        => 'gzip -9f',
        SUFFIX          => '.gz',
    },
);
my %MM_Compat=(
    '5.46'              => [qw(PM_FILTER)],
    '6.31'              => [qw(LICENSE)],
    '6.46'              => [qw(META_MERGE)],
    '6.48'              => [qw(MIN_PERL_VERSION)],
    '6.52'              => [qw(CONFIGURE_REQUIRES)],
    '6.5503'            => [qw(BUILD_REQUIRES)],
    '6.64'              => [qw(TEST_REQUIRES)],
);
while (my ($mm_ver_test, $name_ar)=each(%MM_Compat)) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete(@WriteMakefile{@{$name_ar}});
    }
}
WriteMakefile(%WriteMakefile);
