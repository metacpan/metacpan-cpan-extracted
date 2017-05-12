use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Read/Write ordered .ini style files with as little code as possible',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST Config-Tiny-Ordered-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'Config-Tiny-Ordered',
 NAME      => 'Config::Tiny::Ordered',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 Config::Tiny => 2.12,
	 Test::More   => 0.47,
	 Test::Pod    => 0,
	},
	VERSION_FROM => 'lib/Config/Tiny/Ordered.pm',
);
