
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Client for the Atlassian Confluence wiki, based on RPC::XML",
  "AUTHOR" => "Asgeir Nilsen, Giles Lewis, Martin Ellis, Torben K. Jensen, Heiko Jansen <hjansen\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Confluence-Client-XMLRPC",
  "EXE_FILES" => [],
  "LICENSE" => "gpl",
  "NAME" => "Confluence::Client::XMLRPC",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "RPC::XML" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "2.5",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "RPC::XML" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



