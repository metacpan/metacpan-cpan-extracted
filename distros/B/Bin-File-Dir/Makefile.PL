use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'Bin::File::Dir' , 
  VERSION_FROM    => 'lib/Bin/File/Dir.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw { dirhier depthdepth dirhier dirdig dirdim fileday samesize updir } ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
