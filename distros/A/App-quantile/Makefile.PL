use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App::quantile',
  VERSION_FROM => 'quantile.pm',
  EXE_FILES => [ 'quantile' ],
  AUTHOR => 'Toshiyuki SHIMONO (bin4tsv at gmail.com)',
  LICENSE => 'perl_5',
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/tulamili/App-quantile.git',
               web  => 'https://github.com/tulamili/App-quantile',
           },
           bugtracker => {
               web => 'https://github.com/tulamili/App-quantile/issues'
           },
       },
  },
);

