use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::csv2tsv' ,
  VERSION_FROM    => 'csv2tsv.pm' , 
  EXE_FILES => [ 'csv2tsv' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
