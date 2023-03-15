use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::cmdout2git' ,
  VERSION_FROM    => 'cmdout2git.pm' , 
  EXE_FILES => [ 'cmdout2git' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
