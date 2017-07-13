package My::Builder::Cygwin;

use strict;
use warnings;
use base 'My::Builder';

my $makefile = 'Makefile.gnu';
#my $makefile = 'Makefile.cygwin'; ## troubles with Source/LibJXR/common/include/guiddef.h

sub make_clean {
  my $self = shift;
  $self->do_system( $self->get_make, '-f', $makefile, "clean" );
}

sub make_inst {
  my ($self, $prefixdir) = @_;
  my @cmd = ( $self->get_make, '-f', $makefile, "CYGWIN=1", "DISTDIR=$prefixdir", "CC=gcc", "CXX=g++", "dist" );
  warn "[cmd: ".join(' ',@cmd)."]\n";
  $self->do_system(@cmd) or die "###ERROR### make failed [$?]";
}

1;
