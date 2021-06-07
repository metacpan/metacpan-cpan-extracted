use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'Bin::Text::Color::Plus' ,
  VERSION_FROM    => 'lib/Bin/Text/Color/Plus.pm' , 
  EXE_FILES => [ map {"scripts/$_"} qw{ colorplus resistorcc backcolor } ],  
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
