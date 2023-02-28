use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::madeafter' ,
  VERSION_FROM => 'madeafter.pm' ,
  EXE_FILES => [ qw[ madeafter ] ] , 
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' ,
  LICENSE => 'perl_5'
);

