#
# $Id: Makefile.PL,v 1.10 2007-01-27 13:33:24 gomor Exp $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'DBIx::SQLite::Simple',
   AUTHOR        => 'GomoR <gomor_at_cpan.org>',
   VERSION_FROM  => 'lib/DBIx/SQLite/Simple.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/DBIx/SQLite/Simple.pm',
   PREREQ_PM     => {
      'DBD::SQLite' => 0,
      'Class::Gomor' => 0,
      'DBI' => 0,
   },
   MIN_PERL_VERSION => '5.6.1',
);
