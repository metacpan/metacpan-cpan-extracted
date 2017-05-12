
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'CatalystX-FeedbackMessages',
  NAME      => 'CatalystX::FeedbackMessages',
  AUTHOR    => "Devin\ Austin\ \<dhoss\@cpan\.org\>",
  ABSTRACT  => "Easy\ way\ to\ stuff\ \"status\"\ messages\ into\ your\ stash",
  VERSION   => '0.0603',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Catalyst" => '5.80004',
    "Test::Simple" => '0.88',
    "Moose" => '0.93',
    "Catalyst::Action::RenderView" => '0.13',
  },
  test => {TESTS => 't/*.t'}
);

