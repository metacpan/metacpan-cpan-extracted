
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Add debugger command to see stack trace as HTML',
  'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>',
  'BUILD_REQUIRES' => {
    'Carp' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'DB-Pluggable-StackTraceAsHTML',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DB::Pluggable::StackTraceAsHTML',
  'PREREQ_PM' => {
    'Browser::Open' => '0',
    'DB::Pluggable::Role::Initializer' => '0',
    'Devel::StackTrace::AsHTML' => '0',
    'Devel::StackTrace::WithLexicals' => '0',
    'File::Slurp' => '0',
    'Role::Basic' => '0'
  },
  'VERSION' => '1.111750',
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



