
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'DBICx-Shortcuts',
  NAME      => 'DBICx::Shortcuts',
  AUTHOR    => "Pedro\ Melo\ \<melo\@cpan\.org\>",
  ABSTRACT  => "Setup\ a\ class\ with\ shortcut\ methods\ to\ the\ sources\ of\ a\ DBIx\:\:Class\-based\ schema",
  VERSION   => '0.007',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.92',
    "Test::Exception" => '0',
    "parent" => '0',
    "File::Temp" => '0',
    "DBIx::Class" => '0',
    "Carp" => '0',
  },
  test => {TESTS => 't/*.t'}
);

