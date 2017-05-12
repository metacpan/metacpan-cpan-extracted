use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME             => 'Dancer2::Plugin::Emailesque',
   AUTHOR           => q{Alberto Simoes <ambs@cpan.org>},
   VERSION_FROM     => 'lib/Dancer2/Plugin/Emailesque.pm',
   ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Emailesque.pm',
   LICENSE          => 'Artistic_2_0',
   PL_FILES         => {},
   MIN_PERL_VERSION => 5.006,
   CONFIGURE_REQUIRES => {
                          'ExtUtils::MakeMaker' => 0,
                         },
   BUILD_REQUIRES => {
                      'Test::More' => 0,
                     },
   PREREQ_PM => {
                 'Dancer2'     => '0.05',
                 'Emailesque'  => '1.200007',
                },
   dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean      => { FILES => 'Dancer2-Plugin-Emailesque-*' },
   META_MERGE =>
   {
    "meta-spec" => { version => 2 },
    resources =>
    {
     repository => {
                    type => 'git',
                     web => 'https://github.com/ambs/Dancer2-Plugin-Emailesque.git',
                   },
    },
   },
  );
