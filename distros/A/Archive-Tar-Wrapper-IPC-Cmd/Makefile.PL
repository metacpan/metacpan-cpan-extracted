
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Archive-Tar-Wrapper minus IPC::Run, IO::Pty",
  "AUTHOR" => "Krzysztof Bieszczad <kbsw\@hushmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Archive-Tar-Wrapper-IPC-Cmd",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Archive::Tar::Wrapper::IPC::Cmd",
  "PREREQ_PM" => {
    "Cwd" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::Path" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "IPC::Cmd" => 0,
    "Log::Log4perl" => 0
  },
  "VERSION" => "0.22",
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



