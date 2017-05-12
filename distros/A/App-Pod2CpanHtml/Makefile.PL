use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'        => 'John McNamara (jmcnamara@cpan.org)',
    'ABSTRACT_FROM' => 'lib/App/Pod2CpanHtml.pm',
    'NAME'          => 'App::Pod2CpanHtml',
    'VERSION_FROM'  => 'lib/App/Pod2CpanHtml.pm',
    'NEEDS_LINKING' => 0,
    'PREREQ_PM'     => { 'Pod::Simple' => 0, },
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'EXE_FILES'     => ['bin/pod2cpanhtml'],
    'LICENSE'       => 'perl',
);

