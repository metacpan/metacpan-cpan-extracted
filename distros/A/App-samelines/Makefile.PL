use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::samelines' ,
  VERSION_FROM    => 'samelines.pm' , 
  EXE_FILES => [ 'samelines' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-samelines.git',
               web  => 'https://github.com/tulamili/App-samelines',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-samelines/issues'
           },
       },
  },
) ;
 
