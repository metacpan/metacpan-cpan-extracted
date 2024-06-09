use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Data::ISO8583',
  VERSION_FROM    => 'lib/Data/ISO8583.pm',
  LICENSE         => 'gpl_2',
  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-data-iso8583.git',
        web  => 'https://github.com/cade-vs/perl-data-iso8583',
      },
    },
  },
);
