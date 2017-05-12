use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Shark',
    'VERSION_FROM' => 'Shark.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

