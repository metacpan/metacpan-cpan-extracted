use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'Convert::Translit',
    'VERSION_FROM' => 'lib/Convert/Translit.pm',
    dist => { COMPRESS => 'gzip -9f' },
);
