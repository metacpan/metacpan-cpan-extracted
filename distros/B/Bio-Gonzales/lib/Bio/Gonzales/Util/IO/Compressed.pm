package Bio::Gonzales::Util::IO::Compressed;

use warnings;
use strict;
use Carp;

use 5.010;
use Data::Dumper;

use Carp;

sub new {
  my $type = shift;
  my $class = ref($type) || $type || die "error in class creation: " . __PACKAGE__;
  @_ == 2 or croak "usage: new $class FH, PID";

  my ( $fh, $pid ) = @_;
  my $me = bless $fh, $class;

  die unless defined $pid;
  ${*$me}{'io_pipe_pid'} = $pid;

  $me;
}

sub close {
  my $fh = shift;
  my $r  = CORE::close($fh);

  waitpid( ${*$fh}{'io_pipe_pid'}, 0 )
    if ( defined ${*$fh}{'io_pipe_pid'} );

  $r;
}

1;
