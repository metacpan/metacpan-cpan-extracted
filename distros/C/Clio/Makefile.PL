
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Command Line Input/Output with sockets and HTTP",
  "AUTHOR" => "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Clio",
  "EXE_FILES" => [
    "bin/clio"
  ],
  "LICENSE" => "perl",
  "NAME" => "Clio",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::Handle" => 0,
    "AnyEvent::Run" => 0,
    "AnyEvent::Socket" => 0,
    "Carp" => 0,
    "Class::Load" => 0,
    "Config::Any" => 0,
    "Config::General" => 0,
    "Data::UUID" => 0,
    "Log::Log4perl" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "Net::Server::Daemonize" => 0,
    "Plack::Request" => 0,
    "Plack::Util" => 0,
    "Protocol::WebSocket::Frame" => 0,
    "Protocol::WebSocket::Handshake::Server" => 0,
    "Role::Tiny" => 0,
    "Scalar::Util" => 0,
    "Twiggy::Server" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.02",
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



