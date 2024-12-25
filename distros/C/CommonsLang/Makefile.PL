use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'CommonsLang',
    VERSION_FROM     => 'CommonsLang.pm',
    ABSTRACT_FROM    => 'CommonsLang.pm',
    AUTHOR           => 'YUPEN',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010001',
    PREREQ_PM        => {
        'strict'   => 0,
        'warnings' => 0,
    },
    test => { TESTS => 't/*.t' },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? (
            META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    repository => {
                        type => 'git',
                        url  => 'https://github.com/dnmfarrell/foo.git',
                        web  => 'https://github.com/dnmfarrell/foo'
                    }
                }
            }
          )
        : ()
    )
);
