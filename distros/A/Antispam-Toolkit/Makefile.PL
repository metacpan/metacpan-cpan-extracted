
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;
check_conflicts();



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Classes, roles, and types for use by other Antispam modules',
  'AUTHOR' => 'Dave Rolsky <autarch@urth.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.88'
  },
  'CONFIGURE_REQUIRES' => {
    'Dist::CheckConflicts' => '0.01',
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Antispam-Toolkit',
  'EXE_FILES' => [],
  'LICENSE' => 'artistic_2',
  'NAME' => 'Antispam::Toolkit',
  'PREREQ_PM' => {
    'Archive::Zip' => '0',
    'BerkeleyDB' => '0',
    'DateTime' => '0',
    'File::Temp' => '0',
    'List::AllUtils' => '0',
    'Moose' => '0',
    'MooseX::Params::Validate' => '0',
    'MooseX::StrictConstructor' => '0',
    'MooseX::Types' => '0',
    'MooseX::Types::Common' => '0',
    'MooseX::Types::Path::Class' => '0',
    'Path::Class' => '0',
    'autodie' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '0.08',
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




sub check_conflicts {
    if ( eval { require 'lib/Antispam/Toolkit/Conflicts.pm'; 1; } ) {
        if ( eval { Antispam::Toolkit::Conflicts->check_conflicts; 1 } ) {
            return;
        }
        else {
            my $err = $@;
            $err =~ s/^/    /mg;
            warn "***\n$err***\n";
        }
    }
    else {
        print <<'EOF';
***
    Your toolchain doesn't support configure_requires, so Dist::CheckConflicts
    hasn't been installed yet. You should check for conflicting modules
    manually by examining the list of conflicts in Antispam::Toolkit::Conflicts once the installation
    finishes.
***
EOF
    }

    # More or less copied from Module::Build
    return if $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && ( -t STDOUT || !( -f STDOUT || -c STDOUT ) );

    sleep 4;
}
