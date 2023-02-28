use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::lastaccess' ,
  VERSION_FROM => 'lastaccess.pm' ,
  EXE_FILES => [ qw[ lastaccess ] ] , 
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' ,
  LICENSE => 'perl_5'
);

