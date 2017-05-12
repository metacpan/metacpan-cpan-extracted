use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Data::Stacker',
  VERSION_FROM    => 'lib/Data/Stacker.pm',
  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-data-stacker.git',
        web  => 'https://github.com/cade-vs/perl-data-stacker',
      },
    },
  },
);
