use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::expskip' ,
  VERSION_FROM    => 'expskip.pm' , 
  EXE_FILES => [ 'expskip' ] ,
  PREREQ_PM => { PerlIO::gzip => 0 } , #=> '0.20' } , 
  PREREQ_FATAL => not 1 ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
