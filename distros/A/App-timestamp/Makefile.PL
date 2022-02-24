use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::timestamp',
  VERSION_FROM => 'timestamp.pm',
  EXE_FILES => [ 'timestamp' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

