use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::colalign',
  VERSION_FROM => 'colalign.pm',
  EXE_FILES => [ 'colalign' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-colalign.git',
               web  => 'https://github.com/tulamili/App-colalign',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-colalign/issues'
           },
       },
  },
);

