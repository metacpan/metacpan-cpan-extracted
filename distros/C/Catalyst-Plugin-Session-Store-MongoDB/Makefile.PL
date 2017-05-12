use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'Catalyst::Plugin::Session::Store::MongoDB',
  ABSTRACT => 'MongoDB Session store for Catalyst',
  AUTHOR => 'Stefan Völkel (bd@bc-bd.org)',

  VERSION_FROM => 'lib/Catalyst/Plugin/Session/Store/MongoDB.pm',

  BUILD_REQUIRES => {
    'String::Random' => 0,
    'Test::More' => 0,
  },

  PREREQ_PM => {
    'Catalyst::Plugin::Session' => '0.27',
    'Data::Dumper' => 0,
    'MongoDB' => 0,
    'Moose' => 0,
  },
);
