use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::colsummary' ,
  VERSION_FROM    => 'colsummary.pm' , 
  EXE_FILES => [ 'colsummary' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
