use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::resistorcc',
  VERSION_FROM => 'resistorcc.pm',
  EXE_FILES => [ 'resistorcc' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-resistorcc.git',
               web  => 'https://github.com/tulamili/App-resistorcc',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-resistorcc/issues'
           },
       },
  },
);

