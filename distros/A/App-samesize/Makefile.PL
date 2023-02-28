use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::samesize' ,
  VERSION_FROM => 'samesize.pm' ,
  EXE_FILES => [ qw[ samesize ] ] , 
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' ,
  LICENSE => 'perl_5'
);

