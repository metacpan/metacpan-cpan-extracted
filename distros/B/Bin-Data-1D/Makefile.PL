use ExtUtils::MakeMaker;

my @scripts1 = qw { expskip freq cat-n summing chars2code gzpaste sampler } ;
my @scripts2 = qw { linedigest idmaker uniq-c wc-l headomit lminusl alluniq digitdemog entrolines } ; 
my @scripts3 = qw { venn } ; 

WriteMakefile (
  NAME            => 'Bin::Data::1D' ,
  VERSION_FROM    => 'lib/Bin/Data/1D.pm' , 
  EXE_FILES => [ map {"scripts/$_"} @scripts1 , @scripts2 , @scripts3 ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
