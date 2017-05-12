package APR::HTTP::Headers::Compat::MagicArray;

use strict;
use warnings;

=head1 NAME

APR::HTTP::Headers::Compat::MagicArray - magic array for multivalue headers

=cut

sub TIEARRAY {
  my ( $class, $fld, $magic, @vals ) = @_;
  return bless {
    a => \@vals,
    f => $fld,
    m => $magic,
  }, $class;
}

sub FETCH {
  my ( $self, $key ) = @_;
  return $self->{a}[$key];
}

# Sync the table with our state

sub _sync {
  my $self = shift;
  my ( $table, $fld, @vals )
   = ( $self->{m}->table, $self->{f}, @{ $self->{a} } );
  $table->set( $fld, shift @vals );
  $table->add( $fld, $_ ) for @vals;
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  $self->{a}[$key] = $value;
  $self->_sync;
}

sub FETCHSIZE { scalar @{ shift->{a} } }
sub STORESIZE { }

sub CLEAR {
  my $self = shift;
  $self->{a} = [];
  $self->_sync;
}

sub PUSH {
  my ( $self, @list ) = @_;
  push @{ $self->{a} }, @list;
  $self->_sync;
}

sub POP {
  my $self = shift;
  my $val  = pop @{ $self->{a} };
  $self->_sync;
  return $val;
}

sub SHIFT {
  my $self = shift;
  my $val  = shift @{ $self->{a} };
  $self->_sync;
  return $val;
}

sub UNSHIFT {
  my ( $self, @list ) = @_;
  unshift @{ $self->{a} }, @list;
  $self->_sync;
}

sub SPLICE {
  my ( $self, $offset, $length, @list ) = @_;
  splice @{ $self->{a} }, $offset, $length, @list;
  $self->_sync;
}

sub EXISTS {
  my ( $self, $key ) = @_;
  return $key < @{ $self->{a} };
}

sub EXTEND  { }
sub DESTROY { }
sub UNTIE   { }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
