package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper 1.29 qw( Acme::Alien::DontPanic2 !export );

sub myWriteMakefile_as_configure_requires
{
  my(%args) = @_;
  WriteMakefile(
    %args,
    Alien::Base::Wrapper->mm_args,
  );
}

sub myWriteMakefile_as_build_requires
{
  my(%args) = @_;
  WriteMakefile(
    %args,
    CC => '$(FULLPERL) -MAlien::Base::Wrapper=Acme::Alien::DontPanic2 -e cc --',
    LD => '$(FULLPERL) -MAlien::Base::Wrapper=Acme::Alien::DontPanic2 -e ld --',
    BUILD_REQUIRES => {
      'Acme::Alien::DontPanic2' => 0,
      'Alien::Base::Wrapper' => 0,
    },
  );
}

sub myWriteMakefile
{
  goto \&myWriteMakefile_as_configure_requires;
}

1;
