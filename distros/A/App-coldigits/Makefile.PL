use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::coldigits' ,
  VERSION_FROM    => 'coldigits.pm' , 
  EXE_FILES => [ 'coldigits' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-coldigits.git',
               web  => 'https://github.com/tulamili/App-coldigits',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-coldigits/issues'
           },
       },
  },
) ;

