
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Search and browse Mini CPAN",
  "AUTHOR" => "Leon Brocard <acme\@astray.com>, Christian Walde <walde.christian\@googlemail.com>",
  "BUILD_REQUIRES" => {
    "CGI" => "3.16",
    "Capture::Tiny" => 0,
    "Compress::Zlib" => 0,
    "Exporter" => 0,
    "File::Find" => 0,
    "File::Path" => "2.08",
    "File::Slurp" => 0,
    "File::Temp" => 0,
    "HTTP::Response" => 0,
    "Test::Builder" => 0,
    "Test::InDistDir" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPAN-Mini-Webserver",
  "EXE_FILES" => [
    "bin/minicpan_webserver"
  ],
  "LICENSE" => "perl",
  "NAME" => "CPAN::Mini::Webserver",
  "PREREQ_PM" => {
    "App::Cache" => 0,
    "Archive::Peek" => "0.33",
    "CPAN" => 0,
    "CPAN::Mini::App" => "0.565",
    "Encode" => 0,
    "File::Spec::Functions" => 0,
    "File::Type" => 0,
    "Getopt::Long" => 0,
    "HTTP::Server::Simple" => "0.34",
    "HTTP::Server::Simple::CGI" => 0,
    "Lingua::StopWords" => 0,
    "List::MoreUtils" => 0,
    "MIME::Base64" => 0,
    "Module::InstalledVersion" => 0,
    "Moose" => 0,
    "PPI" => 0,
    "PPI::HTML" => 0,
    "Parse::CPAN::Authors" => 0,
    "Parse::CPAN::Meta" => 0,
    "Parse::CPAN::Packages" => "2.35",
    "Parse::CPAN::Whois" => "0.02",
    "Path::Class" => 0,
    "Pod::Simple::HTML" => 0,
    "Pod::Simple::Text" => 0,
    "Safe" => 0,
    "Search::QueryParser" => 0,
    "Search::Tokenizer" => 0,
    "String::CamelCase" => 0,
    "Template::Declare" => 0,
    "Template::Declare::Tags" => "0.29",
    "Text::Unidecode" => 0,
    "Try::Tiny" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.58",
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



