use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::collen',
  VERSION_FROM => 'collen.pm',
  EXE_FILES => [ 'collen' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-collen.git',
               web  => 'https://github.com/tulamili/App-collen',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-collen/issues'
           },
       },
  },
);

