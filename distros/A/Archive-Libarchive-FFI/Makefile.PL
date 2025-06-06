BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.010000; 1}) {
    print "Perl 5.010000 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.63.
use strict;
use warnings;
use 5.010000;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT"           => "(Deprecated) Perl bindings to libarchive via FFI",
  "AUTHOR"             => "Graham Ollis <plicease\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "FFI::Raw"            => "0.29",
    "Module::Build::FFI"  => "0.04"
  },
  "DISTNAME"         => "Archive-Libarchive-FFI",
  "LICENSE"          => "perl",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME"             => "Archive::Libarchive::FFI",
  "PM"               => {
    "lib/Archive/Libarchive/FFI.pm"           => "\$(INST_LIB)/Archive/Libarchive/FFI.pm",
    "lib/Archive/Libarchive/FFI/Callback.pm"  => "\$(INST_LIB)/Archive/Libarchive/FFI/Callback.pm",
    "lib/Archive/Libarchive/FFI/Common.pm"    => "\$(INST_LIB)/Archive/Libarchive/FFI/Common.pm",
    "lib/Archive/Libarchive/FFI/Constant.pm"  => "\$(INST_LIB)/Archive/Libarchive/FFI/Constant.pm",
    "lib/Archive/Libarchive/FFI/Function.pod" => "\$(INST_LIB)/Archive/Libarchive/FFI/Function.pod",
    "lib/Archive/Libarchive/FFI/SweetLite.pm" => "\$(INST_LIB)/Archive/Libarchive/FFI/SweetLite.pm"
  },
  "PREREQ_PM" => {
    "Alien::Libarchive3" => "0.28",
    "Exporter::Tidy"     => 0,
    "FFI::Raw"           => "0.29",
    "FFI::Util"          => "0.06"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.98"
  },
  "VERSION" => "0.0902",
  "test"    => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Alien::Libarchive3" => "0.28",
  "Exporter::Tidy"     => 0,
  "FFI::Raw"           => "0.29",
  "FFI::Util"          => "0.06",
  "Test::More"         => "0.98"
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);