use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::12567834' ,
  VERSION_FROM    => '12567834.pm' , 
  EXE_FILES => [ '12567834' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-12567834.git',
               web  => 'https://github.com/tulamili/App-12567834',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-12567834/issues'
           },
       },
  },
) ;

