
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Use C<pm-website> to render and maintain an up-to-date info page",
  "AUTHOR" => "Andrew Grangaard <spazm\@cpan.org>",
  "BUILD_REQUIRES" => {
    "App::Cmd::Tester" => 0,
    "Test::Class" => 0,
    "Test::Class::Load" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "App-PM-Website",
  "EXE_FILES" => [
    "bin/pm-website"
  ],
  "LICENSE" => "perl",
  "NAME" => "App::PM::Website",
  "PREREQ_PM" => {
    "App::Cmd" => 0,
    "App::Cmd::Command" => 0,
    "Config::YAML" => 0,
    "Data::Dumper" => 0,
    "Date::Parse" => 0,
    "DateTime" => 0,
    "DateTime::Format::Strptime" => 0,
    "File::Path" => "2.07",
    "File::Spec" => 0,
    "HTTP::DAV" => 0,
    "IO::TieCombine" => 0,
    "Lingua::EN::Numbers::Ordinate" => 0,
    "Net::Netrc" => 0,
    "POSIX" => 0,
    "Template" => 0,
    "Template::Plugin::DateTime" => 0,
    "Template::Plugin::Gravatar" => 0,
    "Template::Plugin::String::Compare" => 0,
    "YAML::Any" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.131611",
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



