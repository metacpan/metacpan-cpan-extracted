use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Acme::Tao',
    VERSION_FROM => 'Tao.pm',
    AUTHOR => 'James Smith <jsmith@cpan.org>',
    ABSTRACT_FROM => 'Tao.pm',
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
