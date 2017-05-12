use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Loki97',
    'VERSION_FROM' => 'Loki97.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

