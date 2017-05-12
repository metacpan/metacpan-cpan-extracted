
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "An interface to a Riak server.",
  "AUTHOR" => "Andrew Nelson <anelson at cpan.org>, Florian Ragwitz <rafl\@debian.org>",
  "BUILD_REQUIRES" => {
    "MIME::Base64" => 0,
    "Test::Fatal" => 0,
    "Test::Memory::Cycle" => 0,
    "Test::More" => "0.89",
    "Test::Warn" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Riak",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Riak",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::HTTP" => 0,
    "Carp" => 0,
    "Class::Load" => 0,
    "Digest::MD5" => 0,
    "HTTP::Headers" => 0,
    "HTTP::Headers::ActionPack" => "0.05",
    "HTTP::Headers::ActionPack::LinkHeader" => 0,
    "HTTP::Headers::ActionPack::LinkList" => 0,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "HTTP::Status" => 0,
    "HTTP::Throwable::Factory" => 0,
    "JSON" => 0,
    "JSON::XS" => 0,
    "LWP::ConnCache" => 0,
    "LWP::UserAgent" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Clone" => 0,
    "MooseX::StrictConstructor" => 0,
    "Sub::Exporter" => 0,
    "Test::More" => 0,
    "Throwable::Error" => "0.200003",
    "Try::Tiny" => 0,
    "URI" => 0,
    "URL::Encode" => 0,
    "namespace::autoclean" => 0,
    "namespace::clean" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "2.0",
  "test" => {
    "TESTS" => "t/*.t t/async/*.t t/buckets/*.t t/http/*.t t/indexes/*.t t/link/*.t t/mapreduce/*.t t/result/*.t"
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



