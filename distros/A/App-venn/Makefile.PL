use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::venn' ,
  VERSION_FROM    => 'venn.pm' , 
  EXE_FILES => [ 'venn' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
