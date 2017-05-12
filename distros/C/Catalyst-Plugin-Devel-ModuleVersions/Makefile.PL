
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Catalyst-Plugin-Devel-ModuleVersions',
  NAME      => 'Catalyst::Plugin::Devel::ModuleVersions',
  AUTHOR    => "Andreas\ Marienborg\ \<andremar\@cpan\.org\>",
  ABSTRACT  => "Dump\ your\ loaded\ module\ versions\ to\ the\ debug\-screen",
  VERSION   => '0.100330',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Test::MockObject" => '0',
    "Getopt::Long" => '0',
    "base" => '0',
    "FindBin" => '0',
    "Pod::Usage" => '0',
    "TestApp" => '0',
    "Test::More" => '0',
    "ok" => '0',
    "Catalyst" => '0',
    "Test::WWW::Mechanize::Catalyst" => '0',
    "mro" => '0',
    "MRO::Compat" => '0',
    "Catalyst::Test" => '0',
  },
  test => {TESTS => 't/*.t t/author/*.t'}
);

