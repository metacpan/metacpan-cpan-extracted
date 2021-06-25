use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::csv2tsv' ,
  VERSION_FROM    => 'csv2tsv.pm' , 
  EXE_FILES => [ 'csv2tsv' ] ,
  PREREQ_PM => { Text::CSV => 0 } , 
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
