use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::daydiff',
  VERSION_FROM => 'daydiff.pm',
  EXE_FILES => [ 'daydiff' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-daydiff.git',
               web  => 'https://github.com/tulamili/App-daydiff',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-daydiff/issues'
           },
       },
  },
);

