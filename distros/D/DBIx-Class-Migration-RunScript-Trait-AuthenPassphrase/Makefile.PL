
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "RunScript trait to encode values in DBIx::Class::Migration::RunScript",
  "AUTHOR" => "John Napiorkowski <jjnapiork\@cpan.org>",
  "BUILD_REQUIRES" => {
    "DBIx::Class" => 0,
    "DBIx::Class::Migration" => "0.033",
    "DBIx::Class::PassphraseColumn" => 0,
    "File::Path" => 0,
    "File::Spec::Functions" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "DBIx-Class-Migration-RunScript-Trait-AuthenPassphrase",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase",
  "PREREQ_PM" => {
    "Authen::Passphrase" => 0,
    "Class::Load" => 0,
    "Moose" => 0
  },
  "VERSION" => "0.002",
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



