
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Access a DBIx::Class Schema from a CGI::Application",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CGI-Application-Plugin-DBIx-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "CGI::Application::Plugin::DBIx::Class",
  "PREREQ_PM" => {
    "CGI::Application" => 0,
    "DBIx::Class" => "0.08108",
    "FindBin" => 0,
    "SQL::Translator" => "0.11002",
    "Test::Deep" => 0,
    "Test::More" => "0.88",
    "UNIVERSAL" => 0,
    "parent" => 0
  },
  "VERSION" => "1.000101",
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



