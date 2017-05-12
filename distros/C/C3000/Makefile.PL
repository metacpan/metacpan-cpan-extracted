use lib 'inc';
use Devel::AssertOS qw[MSWin32 Cygwin];

use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

open(my $fh, '>>', 'C:\converge\bin\comms.dll') or die "should install converge library!!!";
close $fh if defined $fh;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A perl wrap for C3000 API!!!\r",
  "AUTHOR" => "xiaoyafeng <xyf.xiao\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "C3000",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "C3000",
  "PREREQ_PM" => {
    "DBI" => 0,
    "DateTime" => 0,
    "DateTime::Format::Natural" => 0,
    "DateTime::Format::Oracle" => 0,
    "List::MoreUtils" => 0,
    "Readonly" => 0,
    "Win32::OLE" => "0.17"
  },
  "VERSION" => "1.02",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



