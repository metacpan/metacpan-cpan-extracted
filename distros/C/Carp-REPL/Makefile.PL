use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker;

my $developer = -f '.gitignore';
ExtUtils::MakeMaker->VERSION(6.98) if $developer;

my %WriteMakefileArgs = (
    NAME                => 'Carp::REPL',
    VERSION_FROM        => 'lib/Carp/REPL.pm',
    ABSTRACT_FROM       => 'lib/Carp/REPL.pm',
    AUTHOR              => 'Shawn M Moore, <sartak at gmail.com>',
    LICENSE             => 'perl_5',

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        no_index => {
            package   => [ 'DB', 'Devel::REPL::Plugin::Carp::REPL' ],
        },
        resources => {
            repository => {
                # I actually released from https://github.com/karenetheridge/Carp-REPL,
                # so use that for the most recent version of the code if BP isn't updated.
                url => 'https://github.com/bestpractical/carp-repl.git',
                web => 'https://github.com/bestpractical/carp-repl',
                type => 'git',
            },
            bugtracker => {
                mailto => 'bug-Carp-REPL@rt.cpan.org',
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-REPL',
            },
        },
        x_authority => 'cpan:SARTAK',
        x_contributors => [ # manually added, from git shortlog -e -s -n
            'Shawn M Moore <sartak@bestpractical.com>',
            'Karen Etheridge <ether@cpan.org>',
            'Thomas Sibley <trs@bestpractical.com>',
            'sunnavy <sunnavy@bestpractical.com>',
            'Josh ben Jore <jjore@cpan.org>',
            'Jesse Luehrs <doy@tozt.net>',
            'Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>',
            'Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>',
        ],
    },

    META_ADD => {
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => '0',
                },
            },
            runtime => {
                requires => {
                    'Devel::StackTrace::WithLexicals' => '0',
                    'Devel::LexAlias'                 => '0',
                    'Devel::REPL'                     => '0',
                    'namespace::autoclean'            => '0',
                    'Data::Dump::Streamer'            => '0',
                    'Lexical::Persistence'            => '0',
                },
            },
            test => {
                requires => {
                    'Test::Expect' => '0',
                    'Test::More'   => '0',
                },
            },
        },
    },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
    my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
    next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
             or exists $WriteMakefileArgs{$key};
    my $r = $WriteMakefileArgs{$key} = {
        %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
        %{delete $WriteMakefileArgs{$key} || {}},
    };
    defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
    if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
    if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);
