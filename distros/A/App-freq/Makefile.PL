use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::freq' ,
  VERSION_FROM    => 'freq.pm' , 
  EXE_FILES => [ 'freq' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
