use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Data::Tools',
  VERSION_FROM    => 'lib/Data/Tools.pm',
  LICENSE         => 'gpl_2',
  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-data-tools.git',
        web  => 'https://github.com/cade-vs/perl-data-tools',
      },
    },
  },
);
