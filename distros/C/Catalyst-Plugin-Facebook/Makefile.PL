
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Catalyst-Plugin-Facebook',
  NAME      => 'Catalyst::Plugin::Facebook',
  AUTHOR    => 'Nick\ Gerakines\ \<nick\@gerakines\.net\>',
  ABSTRACT  => 'Build\ Facebook\ applications\ in\ Catalyst\ easier',
  VERSION   => '0.2',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Scalar::Util" => '0',
    "Test::More" => '0',
    "WWW::Facebook::API" => '0',
  },
);
