use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'Bin::TSV::Conv' , 
  VERSION_FROM    => 'lib/Bin/TSV/Conv.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw { csel csv2tsv join2 mtranspose xlsx2tsv } ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
