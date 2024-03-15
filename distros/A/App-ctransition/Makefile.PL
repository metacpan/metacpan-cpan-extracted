use ExtUtils::MakeMaker;

WriteMakefile (
  NAME            => 'App::ctransition' ,
  VERSION_FROM    => 'ctransition.pm' , 
  EXE_FILES => [ 'ctransition' ] ,
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)' , 
  LICENSE => 'perl_5' ,
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-ctransition.git',
               web  => 'https://github.com/tulamili/App-ctransition',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-ctransition/issues'
           },
       },
  },
) ;
 
