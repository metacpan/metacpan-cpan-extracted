use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::chartimes' ,
  VERSION_FROM    => 'chartimes.pm' , 
  EXE_FILES => [ 'chartimes' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-chartimes.git',
               web  => 'https://github.com/tulamili/App-chartimes',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-chartimes/issues'
           },
       },
  },
) ;
 
