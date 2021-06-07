use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'Bin::File::Time' , 
  VERSION_FROM    => 'lib/Bin/File/Time.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw { madeafter lastaccess timeput } ] ,  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
