use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::ggdrv',
  VERSION_FROM => 'ggdrv.pm',
  EXE_FILES => [ 'ggdrv' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

