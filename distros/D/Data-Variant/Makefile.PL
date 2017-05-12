#http://www.perldoc.com/perl5.8.4/lib/ExtUtils/MakeMaker/Tutorial.html

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "Data::Variant",
  VERSION_FROM => "lib/Data/Variant.pm",
  PREREQ_PM => { Switch => 0 }      
);
