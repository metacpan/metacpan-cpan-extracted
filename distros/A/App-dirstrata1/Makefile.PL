use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::dirstrata1',
  VERSION_FROM => 'dirstrata1.pm',
  EXE_FILES => [ 'dirstrata1' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-dirstrata1.git',
               web  => 'https://github.com/tulamili/App-dirstrata1',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-dirstrata1/issues'
           },
       },
  },
);

