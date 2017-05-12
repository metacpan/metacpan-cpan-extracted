
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Bootylicious-Plugin-AjaxLibLoader',
  NAME      => 'Bootylicious::Plugin::AjaxLibLoader',
  AUTHOR    => "Konstantin\ Kapitanov\ \<perlovik\@gmail\.com\>",
  ABSTRACT  => "load\ popular\ AJAX\ JavaScript\ libraries\.",
  VERSION   => '0.05',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Mojo" => '0.999910',
  },
  test => {TESTS => 't/*.t'}
);

