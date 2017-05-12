use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Crypt::Skipjack',
    'VERSION_FROM' => 'Skipjack.pm',
    'PREREQ_PM' => {},
    'AUTHOR' => 'Julius C. Duque',
    'LIBS' => [''],
    'DEFINE' => '',
    'INC' => '-I.',
    'dist' => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
);

