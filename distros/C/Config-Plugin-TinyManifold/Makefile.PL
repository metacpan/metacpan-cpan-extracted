use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'A plugin which uses Config::Tiny with 1 of N sections',
    ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST Config-Plugin-TinyManifold-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'Config-Plugin-TinyManifold',
 NAME      => 'Config::Plugin::TinyManifold',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 Carp         => 1.01,
	 Config::Tiny => 2.14,
	 strict       => 1.03,
 	 Test::More   => 0.94,
 	 Test::Pod    => 1.44,
	 vars         => 1.01,
	 warnings     => 1.03,
 },
 VERSION_FROM => 'lib/Config/Plugin/TinyManifold.pm',
);
