
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Stage-based conveyor-belt-like ticket handling system',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>, Florian Helmberger <fh@univie.ac.at>, Achim Adam <ac@univie.ac.at>, Mark Hofstetter <mh@univie.ac.at>, Heinz Ekker <ek@univie.ac.at>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'Class::Scaffold::App::Test::Classes' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Data-Conveyor',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Data::Conveyor',
  'PREREQ_PM' => {
    'Class::Accessor::Complex' => '0',
    'Class::Scaffold::Accessor' => '0',
    'Class::Scaffold::App::CommandLine' => '0',
    'Class::Scaffold::App::Test::YAMLDriven' => '0',
    'Class::Scaffold::Base' => '0',
    'Class::Scaffold::ConstantImporter' => '0',
    'Class::Scaffold::Delegate::Mixin' => '0',
    'Class::Scaffold::Environment' => '0',
    'Class::Scaffold::Exception' => '0',
    'Class::Scaffold::Exception::Business' => '0',
    'Class::Scaffold::Exception::Container' => '0',
    'Class::Scaffold::Exception::Util' => '0',
    'Class::Scaffold::Factory' => '0',
    'Class::Scaffold::Factory::Type' => '0',
    'Class::Scaffold::HierarchicalDirty' => '0',
    'Class::Scaffold::Log' => '0',
    'Class::Scaffold::Storable' => '0',
    'Class::Scaffold::Test' => '0',
    'Class::Scaffold::Test::Inherited' => '0',
    'Class::Scaffold::Test::UtilLoader' => '0',
    'Class::Scaffold::Util' => '0',
    'Class::Scaffold::YAML::Active' => '0',
    'Class::Scaffold::YAML::Active::Hash' => '0',
    'Class::Scaffold::YAML::Marshall' => '0',
    'Class::Value' => '0',
    'Class::Value::Enum' => '0',
    'Class::Value::Exception::Base' => '0',
    'Class::Value::Exception::NotWellFormedValue' => '0',
    'Class::Value::String' => '0',
    'Compress::Zlib' => '0',
    'DBI' => '0',
    'Data::Container' => '0',
    'Data::Dumper' => '0',
    'Data::Inherited' => '0',
    'Data::Miscellany' => '0',
    'Data::Storage::DBI::Mock' => '0',
    'Data::Storage::DBI::Oracle' => '0',
    'Data::Storage::DBI::Pg' => '0',
    'Data::Storage::DBI::SQLite' => '0',
    'Data::Storage::Memory' => '0',
    'Data::Storage::Null' => '0',
    'Date::Calc' => '0',
    'Error' => '0',
    'Error::Hierarchy' => '0',
    'Error::Hierarchy::Internal' => '0',
    'Error::Hierarchy::Internal::CustomMessage' => '0',
    'Error::Hierarchy::Internal::DBI::STH' => '0',
    'Error::Hierarchy::Test' => '0',
    'Error::Hierarchy::Util' => '0',
    'Exporter' => '0',
    'Fcntl' => '0',
    'FindBin' => '0',
    'Getopt::Long' => '0',
    'Hash::Flatten' => '0',
    'Hook::Modular' => '0',
    'IO::Handle' => '0',
    'IO::Pager' => '0',
    'Pod::Text' => '0',
    'Storable' => '0',
    'String::FlexMatch::Test' => '0',
    'Sys::Hostname' => '0',
    'Term::Shell::Enhanced' => '0',
    'Test::Builder' => '0',
    'Test::Class' => '0',
    'Test::More' => '0',
    'Text::Table' => '0',
    'Time::HiRes' => '0',
    'YAML' => '0',
    'YAML::Active' => '0',
    'YAML::Marshall' => '0',
    'charnames' => '0',
    'constant' => '0',
    'once' => '0',
    'overload' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.103130',
  'test' => {
    'TESTS' => 't/*.t'
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



