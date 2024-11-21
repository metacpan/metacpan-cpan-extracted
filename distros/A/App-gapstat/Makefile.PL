use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::gapstat' ,
  VERSION_FROM    => 'gapstat.pm' , 
  EXE_FILES => [ 'gapstat' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-gapstat.git',
               web  => 'https://github.com/tulamili/App-gapstat',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-gapstat/issues'
           },
       },
  },
) ;

