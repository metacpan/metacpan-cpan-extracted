use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME               => 'Catalyst::Plugin::Session::Store::CHI::CHI',
  AUTHOR             => q{Motortrak Ltd <duncan.garland@motortrak.com>},
  VERSION_FROM       => 'lib/Catalyst/Plugin/Session/Store/CHI/CHI.pm',
  ABSTRACT_FROM      => 'lib/Catalyst/Plugin/Session/Store/CHI/CHI.pm',
  LICENSE            => 'Artistic_2_0',
  PL_FILES           => {},
  MIN_PERL_VERSION   => 5.006,
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
  BUILD_REQUIRES     => {
    'Test::More'                       => 0,
    'MRO::Compat'                      => 0,
    'Catalyst'                         => '5.8',
    'CHI'                              => '0',
    'Moose'                            => '0',
    'Class::Data::Inheritable'         => '0',
    'Catalyst::Plugin::Session::Store' => '0',
    'Path::Class'                      => '0',
    'File::Spec'                       => '0',
    'Catalyst::Utils'                  => '0',
    'Carp::Assert'                     => '0',
    'namespace::autoclean'             => '0',
  },
  PREREQ_PM => {

    #'ABC'              => 1.6,
    #'Foo::Bar::Module' => 5.0401,
  },
  TEST_REQUIRES => { 'Catalyst::Model::DBIC::Schema' => '0', },
  dist          => { COMPRESS                        => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Catalyst-Plugin-Session-Store-CHI-CHI-*' },
);
