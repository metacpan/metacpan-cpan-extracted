use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Data::Tools',
  VERSION_FROM    => 'lib/Data/Tools.pm',
  LICENSE         => 'gpl_2',

  # the test suite uses .pl instead of the default .t
  test            => { TESTS => 't/*.pl' },

  TEST_REQUIRES   => {
    'Test::More'                       => 0,
    'File::Temp'                       => 0,
    },

  PREREQ_PM       => {

    # Data::Tools
    'JSON'                             => 0,
    'Digest::SHA1'                     => 0,
    'Digest::Whirlpool'                => 0,

    # Data::Tools::Time
    'Date::Calc'                       => 0,
    'Time::JulianDay'                  => 0,

    # Data::Tools::Math
    'Math::BigFloat'                   => 0,

    },

  META_MERGE      => {
    'meta-spec' => { version => 2 },
    prereqs => {
      runtime => {
        recommends => {
          # loaded on demand by Data::Tools::Serialization, needed only by
          # xml2perl() and perl2xml(), everything else works without it
          'XML::Bare' => 0,
        },
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-data-tools.git',
        web  => 'https://github.com/cade-vs/perl-data-tools',
      },
    },
  },
);
