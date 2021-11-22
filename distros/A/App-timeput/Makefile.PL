use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::timeput',
  VERSION_FROM => 'timeput.pm',
  EXE_FILES => [ 'timeput' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

