use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Data::Tools::Process',
  VERSION_FROM    => 'lib/Data/Tools/Process.pm',
  LICENSE         => 'gpl_2',

  # the test suite uses .pl instead of the default .t
  test            => { TESTS => 't/*.pl' },

  TEST_REQUIRES   => {
    'Test::More'                       => 0,
    'File::Temp'                       => 0,
    },

  PREREQ_PM       => {

    # Data::Tools::Process
    'Data::Tools'                      => '1.60',

    # Data::Tools::Process::ForkPool
    'Net::Tools'                       => '1.60',
    'Exception::Sink'                  => 0,

    },

  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-data-tools-process.git',
        web  => 'https://github.com/cade-vs/perl-data-tools-process',
      },
    },
  },
);
