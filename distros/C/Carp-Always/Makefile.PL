
use 5.006;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

my %META = (
    'dynamic_config' => 0,
    'meta-spec'      => { version => 2 },
    'prereqs'        => {
        develop => {
            requires => {    # author tests
                'Test::Pod'           => '1.18',
                'Test::Pod::Coverage' => '1.04',
            }
        },
    },
    'resources' => {
        repository => {
            type => 'git',
            url  => 'git://github.com/aferreira/cpan-Carp-Always.git',
            web  => 'https://github.com/aferreira/cpan-Carp-Always'
        },
        bugtracker => {
            web => 'https://github.com/aferreira/cpan-Carp-Always/issues',
        },
    },
);

WriteMakefile(
    NAME         => 'Carp::Always',
    VERSION_FROM => 'lib/Carp/Always.pm',
    PREREQ_PM    => {
        Carp => 0,
    },
    ABSTRACT_FROM => 'lib/Carp/Always.pm',
    AUTHOR        => 'Adriano Ferreira <ferreira@cpan.org>',
($EUMM_VERSION >= 6.31 ? (
    LICENSE       => 'perl',
) : ()),
($EUMM_VERSION > 6.48 ? (
    MIN_PERL_VERSION => 5.006,
) : ()),
($EUMM_VERSION > 6.4501 ? (
    META_MERGE    => \%META,
) : ()),
($EUMM_VERSION >= 6.6303 ? (
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Base' => 0,    # minimum test
    },
) : ()),
);
