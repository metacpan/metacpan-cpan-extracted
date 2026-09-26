use 5.010;
use strict;
use warnings;
use version;

use ExtUtils::MakeMaker;

#  Add documentation maintenance when the companion plugin is installed
#
eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1;
};


#  Add publication targets
#
eval {
    require ASPEER::MakeMaker::Markdown::Publish;
    ASPEER::MakeMaker::Markdown::Publish->import();
    1;
};

my $mm_ver=$ExtUtils::MakeMaker::VERSION;
if ($mm_ver=~/_/) {
    $mm_ver=eval($mm_ver);
    die $@ if $@;
}
my %WriteMakefile=(
    NAME             => 'ASPEER::MakeMaker::Markdown::Publish',
    DISTNAME         => 'ASPEER-MakeMaker-Markdown-Publish',
    VERSION_FROM     => 'lib/ASPEER/MakeMaker/Markdown/Publish.pm',
    ABSTRACT_FROM    => 'lib/ASPEER/MakeMaker/Markdown/Publish.pm',
    EXE_FILES        => [],
    LICENSE          => 'perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {
        'ASPEER::MakeMaker'                  => '1.010',
        'ASPEER::MakeMaker::Markdown::Pod'   => '1.010',
        'Markdown::Publish'                   => '1.001',
        'Cwd'                                => 0,
        'File::Basename'                     => 0,
        'File::Spec'                         => 0,
        'JSON::PP'                           => 0,
        'MIME::Base64'                       => 0,
        'Exporter'                           => 0,
        'strict'                             => 0,
        'vars'                               => 0,
        'warnings'                           => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'version'             => 0,
    },
    TEST_REQUIRES => {
        'Config'     => 0,
        'File::Path' => 0,
        'File::Temp' => 0,
        'Test::More' => 0,
    },
    META_MERGE => {
        x_authority => 'cpan:ASPEER',
        'meta-spec' => {version => 2},
        resources   => {
            bugtracker => {
                web => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Publish/issues',
            },
            homepage   => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Publish',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Publish.git',
                web  => 'https://github.com/aspeer/pm-ASPEER-MakeMaker-Markdown-Publish',
            },
        },
    },
    depend => {Makefile => '$(VERSION_FROM)'},
    dist   => {COMPRESS => 'gzip -9f', SUFFIX => '.gz'},
);
my %MM_Compat=(
    '6.31'   => [qw(LICENSE)],
    '6.46'   => [qw(META_MERGE)],
    '6.48'   => [qw(MIN_PERL_VERSION)],
    '6.52'   => [qw(CONFIGURE_REQUIRES)],
    '6.64'   => [qw(TEST_REQUIRES)],
);
while (my ($mm_ver_test, $name_ar)=each(%MM_Compat)) {
    if (version->parse($mm_ver) < version->parse($mm_ver_test)) {
        delete(@WriteMakefile{@{$name_ar}});
    }
}
WriteMakefile(%WriteMakefile);
