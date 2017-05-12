
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'use BioPerl\'s Bio::SeqIO as a Catalyst view',
  'AUTHOR' => 'Robert Buels <rbuels@cpan.org>',
  'BUILD_REQUIRES' => {
    'Bio::PrimarySeq' => '0',
    'Catalyst' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Test' => '0',
    'FindBin' => '0',
    'Test::More' => '0.89'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Catalyst-View-Bio-SeqIO',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::View::Bio::SeqIO',
  'PREREQ_PM' => {
    'Bio::Root::Version' => '1.005002',
    'Bio::SeqIO' => '0',
    'Catalyst::Action::RenderView' => '0',
    'Catalyst::View' => '0',
    'IO::String' => '0',
    'Moose' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.02',
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



