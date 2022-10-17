use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::denomfind',
  VERSION_FROM => 'denomfind.pm',
  EXE_FILES => [ 'bin/denomfind' , 'bin/primefind' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

