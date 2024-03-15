use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::colcount' ,
  VERSION_FROM    => 'colcount.pm' , 
  EXE_FILES => [ 'colcount' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-colcount.git',
               web  => 'https://github.com/tulamili/App-colcount',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-colcount/issues'
           },
       },
  },
) ;
 
