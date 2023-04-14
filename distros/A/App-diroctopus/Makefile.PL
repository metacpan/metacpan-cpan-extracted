use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::diroctopus',
  VERSION_FROM => 'diroctopus.pm',
  EXE_FILES => [ 'diroctopus' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-diroctopus.git',
               web  => 'https://github.com/tulamili/App-diroctopus',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-diroctopus/issues'
           },
       },
  },
);

