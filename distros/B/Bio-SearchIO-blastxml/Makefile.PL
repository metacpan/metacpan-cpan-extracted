# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "A SearchIO implementation of NCBI Blast XML parsing.",
  "AUTHOR" => "cjfields <cjfields\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Bio-SearchIO-blastxml",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.006",
  "NAME" => "Bio::SearchIO::blastxml",
  "PREREQ_PM" => {
    "Bio::Root::Root" => 0,
    "Bio::SearchIO" => 0,
    "Bio::SearchIO::IteratedSearchResultEventBuilder" => 0,
    "IO::File" => 0,
    "Time::HiRes" => 0,
    "XML::SAX" => 0,
    "XML::SAX::Base" => 0,
    "base" => 0,
    "strict" => 0
  },
  "TEST_REQUIRES" => {
    "Bio::Root::Test" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::More" => 0,
    "lib" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.70",
  "test" => {
    "TESTS" => "t/*.t t/SearchIO/*.t"
  }
);


my %FallbackPrereqs = (
  "Bio::Root::Root" => 0,
  "Bio::Root::Test" => 0,
  "Bio::SearchIO" => 0,
  "Bio::SearchIO::IteratedSearchResultEventBuilder" => 0,
  "File::Spec" => 0,
  "IO::File" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Test::More" => 0,
  "Time::HiRes" => 0,
  "XML::SAX" => 0,
  "XML::SAX::Base" => 0,
  "base" => 0,
  "lib" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
