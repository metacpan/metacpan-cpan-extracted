use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::colgrep' ,
  VERSION_FROM    => 'colgrep.pm' , 
  EXE_FILES => [ 'colgrep' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
