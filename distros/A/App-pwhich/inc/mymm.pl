package mymm;

use strict;
use warnings;
use File::Copy qw( copy );
use ExtUtils::MakeMaker ();

sub myWriteMakefile
{
  my %args = @_;

  if(($ENV{PERL_APP_PWHICH_NO_PREFIX} || '') eq 'no-prefix')
  {
    push @{ $args{EXE_FILES} }, 'bin/where', 'bin/which';
    copy('bin/pwhich', 'bin/which') or die "copy failed: $!";
    copy('bin/pwhere', 'bin/where') or die "copy failed: $!";
  }

  if($^O eq 'MSWin32')
  {
    $args{PREREQ_PM}->{'Shell::Guess'} = 0;
    $args{PREREQ_PM}->{'File::Which'}  = 1.23;
  }

  ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;
