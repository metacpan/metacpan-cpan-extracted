use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'Bin::Gen::Rand' ,
  VERSION_FROM    => 'lib/Bin/Gen/Rand.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw { boxmuller cointoss horsekicks saikoro t1generate t2generate } ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
