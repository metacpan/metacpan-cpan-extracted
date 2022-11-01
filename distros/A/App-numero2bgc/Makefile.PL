use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::numero2bgc' ,
  VERSION_FROM    => 'numero2bgc.pm' , 
  EXE_FILES => [ 'numero2bgc' ] ,
  PREREQ_PM => {  } ,
  PREREQ_FATAL => not 1 ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
