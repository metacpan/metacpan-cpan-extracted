use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::Bin4TSV::6' ,
  VERSION_FROM    => '6.pm' , 
  EXE_FILES => [ qw [ colgrep colsummary crosstable csel freq venn ] ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
