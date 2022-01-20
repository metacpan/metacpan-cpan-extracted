use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::sizecheck',
  VERSION_FROM => 'sizecheck.pm',
  EXE_FILES => [ 'sizecheck' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

