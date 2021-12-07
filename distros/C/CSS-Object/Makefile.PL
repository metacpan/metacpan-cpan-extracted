use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'CSS::Object',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    VERSION_FROM        => 'lib/CSS/Object.pm',
    ABSTRACT_FROM       => 'lib/CSS/Object.pm',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => 
    {
        'strict'        => 0,
        'warnings'      => 0,
        'parent'        => 0,
        'overload'      => '1.22',
        'overloading'   => '0.02',
        'Devel::Confess'    => '0.009004',
        'Module::Generic'   => 'v0.17.3',
        'Want'          => '0.29',
    },
    TEST_REQUIRES =>
    {
        'Test::More'    => '1.302162',
        'Test::Pod'     => '1.52',
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => 'v5.26.1',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CSS-Object-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/CSS-Object.git',
                web         => 'https://git.deguest.jp/jack/CSS-Object',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/CSS-Object/issues',
            },
            license => [ 'http://dev.perl.org/licenses/' ],
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
