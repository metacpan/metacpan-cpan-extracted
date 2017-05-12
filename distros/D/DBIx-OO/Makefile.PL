use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME                => 'DBIx::OO',
   AUTHOR              => 'Mihai Bazon <mishoo@cpan.org>',
   VERSION_FROM        => 'lib/DBIx/OO.pm',
   ABSTRACT_FROM       => 'lib/DBIx/OO.pm',
   PL_FILES            => {},

   PREREQ_PM           => {
                           'version'                   => 0,
                           'Test::More'                => 0,
                           'Test::Pod::Coverage'       => 0,
                           'Module::Load'              => 0,
                           'Class::Data::Inheritable'  => 0,
                           'SQL::Abstract'             => 0,
                           'DBI'                       => 0,
                          },

   dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean               => { FILES => 'DBIx-OO-*' },
  );
