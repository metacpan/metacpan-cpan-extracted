
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Catalyst-TraitFor-Request-BrowserDetect',
  NAME      => 'Catalyst::TraitFor::Request::BrowserDetect',
  AUTHOR    => 'Florian\ Ragwitz\ \<rafl\@debian\.org\>',
  ABSTRACT  => 'Browser\ detection\ for\ Catalyst\:\:Requests',
  VERSION   => '0.02',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::More" => '0.88',
    "namespace::autoclean" => '0',
    "HTTP::BrowserDetect" => '0',
    "Catalyst" => '0',
    "aliased" => '0',
    "CatalystX::RoleApplicator" => '0',
    "Moose" => '0',
  },
);
