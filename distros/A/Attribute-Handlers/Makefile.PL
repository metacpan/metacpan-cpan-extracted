use 5.006;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME          => 'Attribute::Handlers',
  VERSION_FROM  => 'lib/Attribute/Handlers.pm',
  INSTALLDIRS   => 'perl',
  'LICENSE'     => 'perl',
  'INSTALLDIRS' => 'perl',
  PREREQ_PM => {
    'parent' => 0,
  },
  ($] >= 5.005 ?
  (ABSTRACT_FROM => 'lib/Attribute/Handlers.pm',
   'AUTHOR'      => 'Damian Conway') : ()),
  META_MERGE => {
    resources => {
      repository  => 'git://perl5.git.perl.org/perl.git perl-git',
      bugtracker  => 'http://rt.perl.org/perlbug/',
      MailingList => 'http://lists.cpan.org/showlist.cgi?name=perl5-porters'
    },
  }

);
