use strict;
use warnings;
 
use 5.008001;
 
use ExtUtils::MakeMaker 6.30;
 
my %WriteMakefileArgs = (
  "ABSTRACT" => "Blow your own trumpet",
  "AUTHOR" => "Ed J <etj\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bugle",
  "LICENSE" => "perl",
  "NAME" => "Bugle",
  PL_FILES => { 'lib/Bugle/sub.xs.PL' => 'lib/Bugle/sub.xs' },
  "PREREQ_PM" => {
    "File::Spec" => "0.8"
  },
  XS => { 'lib/Bugle/sub.xs' => 'lib/Bugle/sub.c' },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
    "Test::Warn" => "0.23"
  },
  "VERSION_FROM" => "lib/Bugle.pm",
  clean => { FILES => 'lib/Bugle/sub.xs' },
);
 
 
my %FallbackPrereqs = (
  "Digest::MD5" => 0,
  "File::Spec" => "0.8",
  "Test::More" => "0.88",
  "Test::Warn" => "0.23"
);
 
 
unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}
 
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
 
WriteMakefile(%WriteMakefileArgs);
