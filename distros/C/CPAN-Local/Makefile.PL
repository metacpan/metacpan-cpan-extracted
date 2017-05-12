
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Hack custom CPAN repos",
  "AUTHOR" => "Peter Shangov <pshangov\@yahoo.com>",
  "BUILD_REQUIRES" => {
    "CPAN::Faker::HTTPD" => 0,
    "File::Find" => 0,
    "Module::Faker::Dist" => 0,
    "Test::More" => 0,
    "Test::Most" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "CPAN-Local",
  "EXE_FILES" => [
    "bin/lpan"
  ],
  "LICENSE" => "perl",
  "NAME" => "CPAN::Local",
  "PREREQ_PM" => {
    "CPAN::DistnameInfo" => 0,
    "CPAN::Index::API" => "0.003",
    "CPAN::Index::API::File::MailRc" => 0,
    "CPAN::Index::API::File::ModList" => 0,
    "CPAN::Index::API::File::PackagesDetails" => 0,
    "CPAN::Inject" => 0,
    "Carp" => 0,
    "Class::Load" => 0,
    "Compress::Zlib" => 0,
    "Config::MVP::Assembler" => 0,
    "Config::MVP::Assembler::WithBundles" => 0,
    "Config::MVP::Reader::Finder" => 0,
    "Config::MVP::Reader::INI" => 0,
    "Digest::MD5" => 0,
    "Dist::Metadata" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "IO::String" => 0,
    "LWP::Simple" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Log::Dispatchouli" => 0,
    "Moose" => 0,
    "Moose::Meta::Class" => 0,
    "Moose::Role" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "MooseX::CoercePerAttribute" => 0,
    "MooseX::Role::Loggable" => "0.009",
    "Path::Class" => 0,
    "Path::Class::URI" => 0,
    "Perl::Version" => 0,
    "Regexp::Common" => 0,
    "String::RewritePrefix" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "URI::file" => 0,
    "namespace::autoclean" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.010",
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



