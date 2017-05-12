
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'low-level routines for working with BLAST tools and formats',
  'AUTHOR' => 'Robert Buels <rmb32@cornell.edu>',
  'BUILD_REQUIRES' => {
    'Bio::SeqIO' => '0',
    'English' => '0',
    'Fatal' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0',
    'Test::Warn' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Bio-BLAST',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Bio::BLAST',
  'PREREQ_PM' => {
    'Bio::PrimarySeq' => '0',
    'Bio::PrimarySeqI' => '0',
    'Bio::Seq::LargePrimarySeq' => '0',
    'Carp' => '0',
    'Class::Accessor::Fast' => '0',
    'File::Basename' => '0',
    'File::Copy' => '0',
    'File::Path' => '0',
    'File::Slurp' => '0',
    'File::Spec::Functions' => '0',
    'IO::Pipe' => '0',
    'IPC::Cmd' => '0',
    'IPC::System::Simple' => '0',
    'List::MoreUtils' => '0',
    'List::Util' => '0',
    'Memoize' => '0',
    'POSIX' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => '0.4',
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



