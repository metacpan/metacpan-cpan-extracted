# use lib "./lib";
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "Data::PropertyList",
  DISTNAME => "Data-PropertyList",
  VERSION_FROM => "lib/Data/PropertyList.pm",
  PREREQ_PM => { 
    'String::Escape' => 1998.12 
  },
  # 'clean' => {FILES => '*/*/*~'},
  'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);

# print "Created makefile. To build, test, and install, run:\n";
# print "\tmake\n";
# print "\tmake test\n";
# print "\tmake install\n";
