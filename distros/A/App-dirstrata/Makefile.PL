use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::dirstrata',
  VERSION_FROM => 'dirstrata.pm',
  EXE_FILES => [ dirstrata ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-dirstrata.git',
               web  => 'https://github.com/tulamili/App-dirstrata',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-dirstrata/issues'
           },
       },
  },
);

