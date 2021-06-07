use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::crosstable' ,
  VERSION_FROM    => 'crosstable.pm' , 
  EXE_FILES => [ 'crosstable' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
