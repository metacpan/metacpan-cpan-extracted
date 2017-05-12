
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Optimistic locking support for DBIx::Class',
  'AUTHOR' => 'Brian Phillips <bphillips@cpan.org>',
  'BUILD_REQUIRES' => {
    'Cwd' => '0',
    'DBIx::Class::Schema' => '0',
    'File::Find' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'DBIx-Class-OptimisticLocking',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'DBIx::Class::OptimisticLocking',
  'PREREQ_PM' => {
    'Carp' => '0',
    'DBIx::Class' => '0.08195',
    'List::Util' => '0'
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



