use strict; use warnings;
BEGIN {
  unless(eval q{ use 5.021008; 1}) {
    print "Perl 5.021008 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.10.
use strict;
use warnings;

use 5.021008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Simplistic interface to pkgconf (like pkg-config)",
  "AUTHOR" => "Graham Ollis <plicease\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Alt-ExtUtils-PkgConfig-PLICEASE",
  "LICENSE" => "lgpl",
  "MIN_PERL_VERSION" => "5.021008",
  "NAME" => "Alt::ExtUtils::PkgConfig::PLICEASE",
  "PM" => {
    "lib/Alt/ExtUtils/PkgConfig/PLICEASE.pm" => "\$(INST_LIB)/Alt/ExtUtils/PkgConfig/PLICEASE.pm",
    "lib/ExtUtils/PkgConfig.pm" => "\$(INST_LIB)/ExtUtils/PkgConfig.pm"
  },
  "PREREQ_PM" => {
    "Carp" => 0,
    "PkgConfig::LibPkgConf::Client" => 0,
    "PkgConfig::LibPkgConf::Util" => 0
  },
  "TEST_REQUIRES" => {
    "English" => 0,
    "PkgConfig::LibPkgConf" => 0,
    "Test::More" => "0.94"
  },
  "VERSION" => "1.15",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "English" => 0,
  "PkgConfig::LibPkgConf" => 0,
  "PkgConfig::LibPkgConf::Client" => 0,
  "PkgConfig::LibPkgConf::Util" => 0,
  "Test::More" => "0.94"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

# begin inserted by Dist::Zilla::Plugin::Alt 0.04
my $alt = $ENV{PERL_ALT_INSTALL} || '';
$WriteMakefileArgs{DESTDIR} =
  $alt ? $alt eq 'OVERWRITE' ? '' : $alt : 'no-install-alt';
# end inserted by Dist::Zilla::Plugin::Alt 0.04
WriteMakefile(%WriteMakefileArgs);
