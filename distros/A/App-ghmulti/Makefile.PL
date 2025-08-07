use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec::Functions;
use autodie;

my $The_Module = 'App::ghmulti';
my $PM_File = catfile('lib', split(/::/, "$The_Module.pm"));
my $Git_URL = 'perl-' . join('-', split(/::/, lc($The_Module)));

my $Version;
open(my $h, '<', $PM_File);
foreach my $line (<$h>) {
  if ($line =~ /\bour\s+\$VERSION\s+.*?["']([^"']+)["']/) {
    $Version = $1;
    last;
  }
}
close($h);
die("VERSION not found in $PM_File") if !$Version;


my %WriteMakefileArgs = (
    NAME             => 'App::ghmulti',
    AUTHOR           => q{Klaus Rindfrey <klausrin@cpan.org.eu>},
    VERSION_FROM     => 'lib/App/ghmulti.pm',
    ABSTRACT_FROM    => 'lib/App/ghmulti.pm',
    EXE_FILES        => ['script/ghmulti'],
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'autodie'               => '0',
        'ExtUtils::MakeMaker'   => '0',
        'File::Spec::Functions' => '0',
    },
    TEST_REQUIRES => {
        'Capture::Tiny' => '0.47',
        'File::Basename' => '0',
        'File::Spec::Functions' => '0',
        'Test::More' => '0',
        'Capture::Tiny' => '0.48',
    },
    PREREQ_PM => {
        'Git::RemoteURL::Parse' => '0.02',
        'GitHub::Config::SSH::UserData' => '0.01'
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url  => "$Git_URL.git",
                web  => "$Git_URL.git",
            },
        },
        bugtracker => {
            web => "$Git_URL/issues"
        },
        provides => { $The_Module => {file => $PM_File,
                                      version => $Version
                                     },
                      'ghmulti'   => {file => 'script/ghmulti', version => $Version}
                    },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => join('-', split(/::/, $The_Module)) . '-*' },
                        );
if ($ENV{AUTHOR_TESTING}) {
    $WriteMakefileArgs{BUILD_REQUIRES} = {
        'Capture::Tiny' => '0.47',
        'Cwd' => '0',
        'File::Basename' => '0',
        'File::Spec::Functions' => '0',
        'File::Temp' => '0',
        'File::chdir' => '0.1011',
        'Pod::Wordlist' => '1.27',
        'Test::CheckManifest' => '1.43',
        'Test::More'  => '0',
        'Test::Pod'       => 1.51,
        'Test::Spelling;' => '0.25',
    };
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
