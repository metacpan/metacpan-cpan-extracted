use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::denomfind',
  VERSION_FROM => 'denomfind.pm',
  EXE_FILES => [ qw[bin/denomfind bin/primefind bin/color0 bin/transpose] ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

