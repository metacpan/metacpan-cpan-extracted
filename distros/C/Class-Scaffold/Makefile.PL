
use strict;
use warnings;

BEGIN { require 5.008; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Large-scale OOP application support',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>, Florian Helmberger <fh@univie.ac.at>, Achim Adam <ac@univie.ac.at>, Mark Hofstetter <mh@univie.ac.at>, Heinz Ekker <ek@univie.ac.at>',
  'BUILD_REQUIRES' => {
    'English' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Class-Scaffold',
  'EXE_FILES' => [
    'bin/cf_dumpenv'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Class::Scaffold',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Class::Accessor::Complex' => '0',
    'Class::Accessor::Constructor' => '0',
    'Class::Accessor::FactoryTyped' => '0',
    'Class::Factory::Enhanced' => '0',
    'Class::Value' => '0',
    'Cwd' => '0',
    'Data::Comparable' => '0',
    'Data::Inherited' => '0',
    'Data::Miscellany' => '0',
    'Data::Storage' => '0',
    'Devel::Caller' => '0',
    'Encode' => '0',
    'Error' => '0',
    'Error::Hierarchy' => '0',
    'Error::Hierarchy::Container' => '0',
    'Error::Hierarchy::Internal' => '0',
    'Error::Hierarchy::Mixin' => '0',
    'Error::Hierarchy::Test' => '0',
    'Error::Hierarchy::Util' => '0',
    'Exporter' => '0',
    'File::Find' => '0',
    'File::Spec::Functions' => '0',
    'FindBin' => '0',
    'Getopt::Inherited' => '0',
    'Getopt::Long' => '0',
    'IO::File' => '0',
    'IO::Handle' => '0',
    'List::Util' => '0',
    'Property::Lookup' => '0',
    'String::FlexMatch' => '0',
    'Sys::Hostname' => '0',
    'Test::Builder' => '0',
    'Test::Class::GetoptControl' => '0',
    'Test::CompanionClasses::Base' => '0',
    'Test::CompanionClasses::Engine' => '0',
    'Test::More' => '0',
    'Time::HiRes' => '0',
    'UNIVERSAL::require' => '0',
    'YAML' => '0',
    'YAML::Active' => '0',
    'YAML::Active::Plugin::Array' => '0',
    'YAML::Active::Plugin::Hash' => '0',
    'YAML::Marshall' => '0',
    'constant' => '0',
    'overload' => '0',
    'parent' => '0'
  },
  'VERSION' => '1.102280',
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



