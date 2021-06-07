use ExtUtils::MakeMaker;

my @scripts = qw{ alluniq backcolor boxmuller cat-n chars2code cointoss colchop colgrep colhashS collen colorplus colpairs colsplit colsummary crosstable csel csv2tsv depthdepth digitdemog dirdig dirdim dirhier entrolines expskip fileday freq gzpaste hashtotal headomit horsekicks idmaker inarow join2 joinn keyvalues kvcmp lastaccess linedigest lminusl madeafter mtranspose quantile resistorcc saikoro samesize sampler summing t1generate t2generate timeput uniq-c updir venn wc-l xlsx2tsv } ;

WriteMakefile (
  NAME            => 'App::Bin4TSV' ,
  VERSION_FROM    => 'lib/App/Bin4TSV.pm' , 
  EXE_FILES => [ map {"scripts/$_"} @scripts ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' 

) ;
 
