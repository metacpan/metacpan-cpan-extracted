use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    'NAME'             => 'DBIx::OpenTracing',
    'VERSION_FROM'     => 'lib/DBIx/OpenTracing.pm',
    'ABSTRACT_FROM'    => 'lib/DBIx/OpenTracing.pod',
    'LICENSE'          => 'artistic2',
    'MIN_PERL_VERSION' => '5.014',
    test               => { TESTS => 't/*.t', },
);
