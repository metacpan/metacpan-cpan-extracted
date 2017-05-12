#
# $Id: Makefile.PL 2000 2015-01-13 18:24:09Z gomor $
#
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Class::Gomor',
   VERSION_FROM  => 'lib/Class/Gomor.pm',
   LICENSE => 'artistic',
   ABSTRACT_FROM => 'lib/Class/Gomor.pm',
   AUTHOR => 'GomoR <gomor_at_cpan.org>',
   MIN_PERL_VERSION => '5.6.1',
   PREREQ_PM     => {
      Data::Dumper => 0,
   },
);
