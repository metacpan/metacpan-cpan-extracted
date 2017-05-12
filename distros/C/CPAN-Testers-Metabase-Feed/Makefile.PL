
use strict;
use warnings;

BEGIN { require 5.010; }

use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Generate Atom feed for CPAN Testers Reports',
  'AUTHOR' => 'David Golden <dagolden@cpan.org>',
  'BUILD_REQUIRES' => {
    'File::Find' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'CPAN-Testers-Metabase-Feed',
  'EXE_FILES' => [],
  'LICENSE' => 'apache',
  'NAME' => 'CPAN::Testers::Metabase::Feed',
  'PREREQ_PM' => {
    'Data::GUID' => '0',
    'DateTime' => '0',
    'DateTime::Format::ISO8601' => '0',
    'File::Slurp' => '0',
    'JSON' => '0',
    'Metabase::Librarian' => '0.013',
    'Moose' => '0',
    'MooseX::Types::ISO8601' => '0',
    'XML::Feed' => '0',
    'autodie' => '2.00',
    'namespace::autoclean' => '0',
    'utf8' => '0'
  },
  'VERSION' => '0.001',
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



