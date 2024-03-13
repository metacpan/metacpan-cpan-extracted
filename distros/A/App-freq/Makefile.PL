use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::freq' ,
  VERSION_FROM    => 'freq.pm' , 
  EXE_FILES => [ 'freq' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-freq.git',
               web  => 'https://github.com/tulamili/App-freq',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-freq/issues'
           },
       },
  },
) ;
 
