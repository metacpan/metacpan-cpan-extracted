package Bio::Gonzales::String::Util;

use warnings;
use strict;
use Carp;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = 0.01_01;

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(common_prefix common_suffix);

sub common_suffix {
  my $comm = shift @_;
  while ( my $e = shift @_ ) {
    $e = substr( $e, -length($comm) )
      if ( length($e) > length($comm) );
    $comm = substr( $comm, -length($e) )
      if ( length($e) < length($comm) );
    if ( ( $e ^ $comm ) =~ /(\0*)$/ ) {
      $comm = substr( $comm, -length($1) );
    } else {
      return undef;
    }
  }
  return $comm;
}

sub common_prefix {
  my $comm = shift @_;
  while ( my $e = shift @_ ) {
    $e = substr( $e, 0, length($comm) )
      if ( length($e) > length($comm) );
    $comm = substr( $comm, 0, length($e) )
      if ( length($e) < length($comm) );
    if ( ( $e ^ $comm ) =~ /^(\0*)/ ) {
      $comm = substr( $comm, 0, length($1) );
    } else {
      return undef;
    }
  }
  return $comm;
}

1;
