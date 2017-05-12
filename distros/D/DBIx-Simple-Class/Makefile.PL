use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'DBIx::Simple::Class',
  AUTHOR           => q{Красимир Беров <berov@cpan.org>},
  VERSION_FROM     => 'lib/DBIx/Simple/Class.pm',
  ABSTRACT_FROM    => 'lib/DBIx/Simple/Class.pod',
  MIN_PERL_VERSION => '5.10.1',
  LICENSE          => 'artistic_2',
  PL_FILES         => {},
  BUILD_REQUIRES   => {
    'DBD::SQLite'    => '1.42',
    'File::Basename' => 0,
    'Cwd'            => 0,
  },
  PREREQ_PM => {
    'Test::More'                => 0,
    'DBIx::Simple'              => 1.35,
    'Params::Check'             => 0,
    'Carp'                      => 0,
    'Data::Dumper'              => 0,
    'File::Path'                => 2.07,
    'File::Spec'                => 0,
    'IO::File'                  => 0,
  },
  META_MERGE    => {
    requires  => {perl => '5.010001'},
    resources => {
      license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository => 'https://github.com/kberov/DBIx--Simple--Class',
      bugtracker => 'https://github.com/kberov/DBIx--Simple--Class/issues'
    },
    no_index => {directory => ['t']}
  },
  test => {TESTS => 't/*.t'},
  dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean => {FILES    => 'DBIx-Simple-Class-*'},
  EXE_FILES => ['examples/dsc_dump_schema.pl']
);
