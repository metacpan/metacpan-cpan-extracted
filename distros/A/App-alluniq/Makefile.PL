use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::alluniq',
  VERSION_FROM => 'alluniq.pm',
  EXE_FILES => [ 'alluniq' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-alluniq.git',
               web  => 'https://github.com/tulamili/App-alluniq',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-alluniq/issues'
           },
       },
  },
);

