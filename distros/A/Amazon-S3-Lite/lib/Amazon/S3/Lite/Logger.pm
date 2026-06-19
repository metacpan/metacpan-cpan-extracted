########################################################################
# Minimal STDERR logger — used when Log::Log4perl is not available
# Implements the same interface callers expect
########################################################################
package Amazon::S3::Lite::Logger;

use strict;
use warnings;

our $VERSION = '1.2.2';

use Readonly;
Readonly::Scalar our $LEVELS => {
  TRACE => 5000,
  DEBUG => 10_000,
  INFO  => 20_000,
  WARN  => 30_000,
  ERROR => 40_000,
  FATAL => 50_000,
};

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  my $self = bless $options, $class;
  $self->{log_level} //= 'warn';

  return $self;
}

########################################################################
sub _log_level {
########################################################################
  my ($self) = @_;

  my $level = uc $self->{log_level};

  return $LEVELS->{$level} // 0;
}

########################################################################
sub trace {  # silent
########################################################################
  my ( $self, $msg ) = @_;
  return if $self->_log_level > $LEVELS->{TRACE};

  return print {*STDERR} "TRACE  - $msg\n";
}

########################################################################
sub debug {
########################################################################
  my ( $self, $msg ) = @_;
  return if $self->_log_level > $LEVELS->{DEBUG};

  return print {*STDERR} "DEBUG  - $msg\n";
}

########################################################################
sub level {
########################################################################
  my ( $self, $level ) = @_;

  return $self->_log_level
    if !$level;

  $self->{log_level} = $level;

  return $level;
}

########################################################################
sub info {
########################################################################
  my ( $self, $msg ) = @_;
  return if $self->_log_level > $LEVELS->{INFO};

  return print {*STDERR} "INFO  - $msg\n";
}

########################################################################
sub warn { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
########################################################################
  my ( $self, $msg ) = @_;
  return if $self->_log_level > $LEVELS->{WARN};

  return print {*STDERR} "WARN  - $msg\n";
}

########################################################################
sub error {
########################################################################
  my ( $self, $msg ) = @_;
  return if $self->_log_level > $LEVELS->{ERROR};

  return print {*STDERR} "ERROR - $msg\n";
}

########################################################################
sub fatal {
########################################################################
  my ( $self, $msg ) = @_;

  return if $self->_log_level > $LEVELS->{FATAL};

  die "FATAL - $msg\n";
}

1;
