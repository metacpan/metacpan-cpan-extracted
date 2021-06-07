use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::csel' ,
  VERSION_FROM    => 'csel.pm' , 
  EXE_FILES => [ 'csel' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
