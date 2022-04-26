use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::dufolder',
  VERSION_FROM => 'dufolder.pm',
  EXE_FILES => [ 'dufolder' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

