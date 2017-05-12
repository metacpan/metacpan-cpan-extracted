use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'B::Lint::Pluggable',
    AUTHOR        => 'Joshua ben Jore <jjore@cpan.org>',
    VERSION_FROM  => 'lib/B/Lint/Pluggable.pm',
    ABSTRACT_FROM => 'lib/B/Lint/Pluggable.pm',
    PREREQ_PM     => {
        'Test::More' => 0,
        'B::Lint'    => '1.09',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'B-Lint-Pluggable-*' },
);
