use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::dirdim',
  VERSION_FROM => 'dirdim.pm',
  EXE_FILES => [ 'dirdim' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

