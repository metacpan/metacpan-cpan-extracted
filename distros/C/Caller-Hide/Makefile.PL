use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'             => 'Caller::Hide',
    'VERSION_FROM'     => 'lib/Caller/Hide.pm',
    'ABSTRACT_FROM'    => 'lib/Caller/Hide.pm',
    'LICENSE'          => 'perl_5',
    'MIN_PERL_VERSION' => '5.010',
    test               => { TESTS => 't/*.t', },
    TEST_REQUIRES      => { 'Test::More' => 0, },
    eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources   => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/s-nez/perl-caller-hide.git',
                    web  => 'https://github.com/s-nez/perl-caller-hide',
                },
            }
        }
    ) : ()
);
