
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "dbic component generating accessors method to get data by a table pointing to a Lookup table (catalog of terms) in a efficient way (cache system)",
  "AUTHOR" => "[Karl Forner <karl.forner\@gmail.com>, thomas Rubattel <rubattel\@cpan.org>]",
  "BUILD_REQUIRES" => {
    "DBIx::Class::Core" => 0,
    "DBIx::Class::Schema" => 0,
    "DDP" => 0,
    "Module::Build" => "0.3601",
    "Moose" => 0,
    "Test::DBIx::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "DBIx-Class-LookupColumn",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "DBIx::Class::LookupColumn",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::MOP" => 0,
    "DBIx::Class" => 0,
    "Data::Dumper" => 0,
    "Hash::FieldHash" => 0,
    "Hash::Merge::Simple" => 0,
    "Smart::Comments" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.10",
  "test" => {
    "TESTS" => "t/*.t t/etc/*.t"
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



