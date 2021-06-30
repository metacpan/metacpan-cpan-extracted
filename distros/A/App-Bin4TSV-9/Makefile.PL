use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::Bin4TSV::9' ,
  VERSION_FROM    => '9.pm' , 
  PREREQ_PM => {
    App::colgrep => 0 ,
    App::colsummary => 0 , 
    App::crosstable => 0 , 
    App::csel => 0 , 
    App::csv2tsv => 0 , 
    App::digitdemog => 0 ,
    App::expandtab => 0 , 
    App::freq => 0 , 
    App::venn => 0 
  },
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 
) ;
 
