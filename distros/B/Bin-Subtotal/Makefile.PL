use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'Bin::Subtotal' , 
  VERSION_FROM    => 'lib/Bin/Subtotal.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw { crosstable digitdemog freq hashtotal quantile summing } ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
