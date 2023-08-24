
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A pure perl BibTeX parser",
  "AUTHOR" => 'Gerhard Gossen <gerhard.gossen@googlemail.com> and Boris Veytsman <boris@varphi.com> and Karl Berry <karl@freefriends.org',
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.31"
  },
  "DISTNAME" => "BibTeX-Parser",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "BibTeX::Parser",
  "PREREQ_PM" => {
    "File::Spec" => 0,
    "IO::File" => 0,
    "IO::String" => 0,
    "LaTeX::ToUnicode" => "0.52",
    "Test::More" => "0.88"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88"
  },
  'VERSION_FROM' => 'lib/BibTeX/Parser.pm',
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



