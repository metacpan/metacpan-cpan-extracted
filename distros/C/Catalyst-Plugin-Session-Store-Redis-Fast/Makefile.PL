use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Catalyst::Plugin::Session::Store::Redis::Fast',
    AUTHOR           => q{Sushrut Pajai <spajai@cpan.org>},
    VERSION_FROM     => 'lib/Catalyst/Plugin/Session/Store/Redis/Fast.pm',
    ABSTRACT         => 'Catalyst-Plugin-Session-Store Redis-Fast plugin',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        "Catalyst" => 0,
        "Catalyst::Plugin::Session::Test::Store" => 0,
        "Catalyst::Test" => 0,
        "File::Spec" => 0,
        "File::Temp" => 0,
        "FindBin" => 0,
        "IO::Handle" => 0,
        "IPC::Open3" => 0,
        "Test::More" => 0,
        "lib" => 0,
        "Redis::Fast" => 0,
        "perl" => "5.006"
    },
    PREREQ_PM => {
        "Catalyst::Plugin::Session::Store" => 0,
        "Class::Data::Inheritable" => 0,
        "MIME::Base64" => 0,
        "MRO::Compat" => 0,
        "Redis::Fast" => 0,
        "Storable" => 0,
        "Try::Tiny" => 0,
        "base" => 0
    },
     META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/spajai/Catalyst-Plugin-Session-Store-Redis-Fast.git',
                web  => 'https://github.com/spajai/Catalyst-Plugin-Session-Store-Redis-Fast',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Plugin-Session-Store-Redis-Fast-*' },
);

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
