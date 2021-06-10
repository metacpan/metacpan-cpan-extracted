use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::expandtab' ,
  VERSION_FROM    => 'expandtab.pm' , 
  EXE_FILES => [ 'expandtab' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
