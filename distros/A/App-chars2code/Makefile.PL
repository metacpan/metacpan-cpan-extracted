use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::chars2code',
  VERSION_FROM => 'chars2code.pm',
  EXE_FILES => [ qw[chars2code ] ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

