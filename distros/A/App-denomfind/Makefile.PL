use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::denomfind',
  VERSION_FROM => 'denomfind.pm',
  EXE_FILES => [ 'denomfind' , 'primefind' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5'
);

