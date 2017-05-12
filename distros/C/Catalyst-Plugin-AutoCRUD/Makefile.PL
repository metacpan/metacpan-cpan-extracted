use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Instant AJAX web front-end for DBIx::Class",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Catalyst" => 0,
    "Catalyst::ScriptRunner" => 0,
    "Class::Data::Inheritable" => 0,
    "DBI" => 0,
    "DBIx::Class" => 0,
    "DBIx::Class::Schema" => 0,
    "File::Temp" => 0,
    "JSON::XS" => 0,
    "Storable" => 0,
    "Test::More" => 0,
    "Test::WWW::Mechanize::Catalyst" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Catalyst-Plugin-AutoCRUD",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Catalyst::Plugin::AutoCRUD",
  "PREREQ_PM" => {
    "Catalyst::Action::RenderView" => 0,
    "Catalyst::Controller" => 0,
    "Catalyst::Model" => 0,
    "Catalyst::Model::DBIC::Schema" => 0,
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::Unicode::Encoding" => 0,
    "Catalyst::Runtime" => "5.70",
    "Catalyst::Utils" => 0,
    "Catalyst::View::JSON" => 0,
    "Catalyst::View::TT" => 0,
    "DBD::SQLite" => 0,
    "DBIx::Class" => "0.08127",
    "DBIx::Class::Schema::Loader" => 0,
    "Data::Dumper" => 0,
    "Data::Page" => 0,
    "Devel::InnerPackage" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Slurp" => 0,
    "File::stat" => 0,
    "JSON" => "2.90",
    "Lingua::EN::Inflect::Number" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "MRO::Compat" => 0,
    "SQL::Translator" => 0,
    "SQL::Translator::Schema" => 0,
    "SQL::Translator::Schema::Table" => 0,
    "Scalar::Util" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "2.200002",
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

