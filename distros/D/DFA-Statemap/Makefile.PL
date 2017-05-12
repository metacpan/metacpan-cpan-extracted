use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'DFA::Statemap',
    'VERSION_FROM'  => 'lib/DFA/Statemap.pm',
    'ABSTRACT'      => 'SMC runtime',
    'LICENSE'       => 'MPL',
    'PREREQ_PM'     => {},
    'AUTHOR'        => 'Francois PERRAD (francois.perrad@gadz.org)',
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

