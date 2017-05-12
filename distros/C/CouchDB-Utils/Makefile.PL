
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "couchdb command line utils",
  "AUTHOR" => "Maroun NAJM <mnajm\@cinemoz.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CouchDB-Utils",
  "EXE_FILES" => [
    "bin/couchdb-utils"
  ],
  "LICENSE" => "bsd",
  "NAME" => "CouchDB::Utils",
  "PREREQ_PM" => {
    "AnyEvent::CouchDB" => 0,
    "App::Cmd::Setup" => 0,
    "Data::Dump" => 0,
    "File::Basename" => 0,
    "File::MimeInfo::Simple" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "File::Spec::Functions" => 0,
    "JSON" => 0,
    "JSON::XS" => 0,
    "MIME::Base64" => 0,
    "URI" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.3",
  "test" => {
    "TESTS" => ""
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



