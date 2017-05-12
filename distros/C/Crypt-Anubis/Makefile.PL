use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Anubis',
    'VERSION_FROM' => 'Anubis.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

