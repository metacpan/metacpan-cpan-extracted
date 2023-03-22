use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::dirdir',
  VERSION_FROM => 'dirdir.pm',
  EXE_FILES => [ dirdir ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

