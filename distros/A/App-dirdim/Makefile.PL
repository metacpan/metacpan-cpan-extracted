use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::dirdim',
  VERSION_FROM => 'dirdim.pm',
  EXE_FILES => [ 'dirdim' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-dirdim.git',
               web  => 'https://github.com/tulamili/App-dirdim',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-dirdim/issues'
           },
       },
  },
);

