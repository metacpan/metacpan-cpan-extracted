########################################################################
# Minimal STDERR logger — used when Log::Log4perl is not available
# Implements the same interface callers expect
########################################################################
package Amazon::S3::Lite::Logger;

use strict;
use warnings;

our $VERSION = '1.1.6';

sub new { return bless {}, shift }

sub trace { }  # silent
sub debug { }  # silent

sub info {
  my ( $self, $msg ) = @_;
  print {*STDERR} "INFO  - $msg\n";
}

sub warn { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
  my ( $self, $msg ) = @_;
  print {*STDERR} "WARN  - $msg\n";
}

sub error {
  my ( $self, $msg ) = @_;
  print {*STDERR} "ERROR - $msg\n";
}

1;
