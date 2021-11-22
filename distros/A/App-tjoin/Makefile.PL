use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::tjoin',
  VERSION_FROM => 'tjoin.pm',
  EXE_FILES => [ 'tjoin' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

