use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::lasttouch' ,
  VERSION_FROM => 'lasttouch.pm' ,
  EXE_FILES => [ qw[ lasttouch ] ] , 
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' ,
  LICENSE => 'perl_5'
);

