package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use Config;
my $makefile = 'Makefile.gnu';

sub make_clean {
  my $self = shift;
  $self->do_system( $self->get_make, '-f', $makefile, "clean" );
}

sub make_inst {
  my ($self, $prefixdir) = @_;

  my @args = ('-f', $makefile, "DISTDIR=$prefixdir");
  
  if ($Config{cc} eq 'gcc') {
    push @args, "CC=gcc";
    push @args, "CXX=g++";
  }
  elsif ($Config{cc} =~ /^(cc|ccache cc)$/) {
    push @args, "CC=cc";
    push @args, "CXX=c++";
  }
  
  my @cmd = ( $self->get_make, @args, "dist" );
  warn "[cmd: ".join(' ',@cmd)."]\n";
  $self->do_system(@cmd) or die "###ERROR### make failed [$?]";
}

1;
