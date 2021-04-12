use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'BigIP::REST',
    VERSION_FROM   => 'lib/BigIP/REST.pm',
    ABSTRACT_FROM  => 'lib/BigIP/REST.pm',
    LICENSE        => 'artistic_2',
    PREREQ_PM => {
        'JSON'           => 0,
        'LWP::UserAgent' => 0,
    },
    CONFIGURE_REQUIRES => {
        'version' => 0,
    },
    TEST_REQUIRES  => {
        'IO::Socket::SSL' => 0,
        'Test::Exception' => 0,
        'Test::More'      => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        'resources' => {
            repository => {
                type => 'git',
                url  => 'git://github.com/Renater/BigIP-REST.git',
                web  => 'https://github.com/Renater/BigIP-REST'
            },
        }
    }
);
