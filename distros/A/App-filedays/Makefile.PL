use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::filedays',
  VERSION_FROM => 'filedays.pm',
  EXE_FILES => [ 'filedays' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

