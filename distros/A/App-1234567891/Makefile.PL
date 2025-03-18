use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::1234567891' ,
  VERSION_FROM    => '1234567891.pm' , 
  EXE_FILES => [ '1234567891' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-1234567891.git',
               web  => 'https://github.com/tulamili/App-1234567891',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-1234567891/issues'
           },
       },
  },
) ;

