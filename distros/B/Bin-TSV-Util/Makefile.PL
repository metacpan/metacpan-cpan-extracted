use ExtUtils::MakeMaker;

my @scripts = qw ( colchop colgrep colhashS collen colorplus colpairs colsplit colsummary crosstable inarow join2 joinn keyvalues kvcmp ) ; 

WriteMakefile (
  NAME            => 'Bin::TSV::Util' ,
  VERSION_FROM    => 'lib/Bin/TSV/Util.pm' , 
  EXE_FILES => [ map {"scripts/$_"} @scripts ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
