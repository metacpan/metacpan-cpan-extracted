package Apache2::PageKit::Param;

# $Id: Param.pm,v 1.5 2001/10/17 21:58:15 borisz Exp $

use strict;

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  return $self;
}

# param method - can be called in two forms
# when passed two arguments ($name, $value), it sets the value of the
# $name attributes to $value
# when passwd one argument ($name), retrives the value of the $name attribute
sub param {
  my ( $self, @p ) = @_;

  unless (@p) {

    # the no-parameter case - return list of parameters
    return () unless defined($self) && $self->{'pkit_parameters'};
    return () unless @{ $self->{'pkit_parameters'} };
    return @{ $self->{'pkit_parameters'} };
  }
  my ( $name, $value );

  # deal with case of setting mul. params with hash ref.
  if ( ref( $p[0] ) eq 'HASH' ) {
    my $hash_ref = shift(@p);
    push( @p, %$hash_ref );
  }
  if ( @p > 1 ) {
    die "param called with odd number of parameters" unless ( ( @p % 2 ) == 0 );
    while ( ( $name, $value ) = splice( @p, 0, 2 ) ) {
      $self->_add_parameter($name);
      $self->{$name} = $value;
    }
  }
  else {
    $name = $p[0];
  }

  if (wantarray) {
    return () unless exists $self->{$name};
    return ref $self->{$name} eq 'ARRAY' ? @{ $self->{$name} } : $self->{$name};
  }

  return $self->{$name} if defined($name);
}

sub _add_parameter {
  my ( $self, $param ) = @_;
  return unless defined $param;
  push( @{ $self->{'pkit_parameters'} }, $param )
    unless defined( $self->{$param} );
}

sub _merge_parameter {
  my $self = shift;
  while ( my ( $k, $v ) = splice @_, 0, 2 ) {
    $self->_add_parameter($k);
    unless ( exists $self->{$k} ) {
      $self->{$k} = $v;
    }
    elsif ( ref $self->{$k} eq 'ARRAY' ) {
      push @{ $self->{$k} }, $v;
    }
    else {
      $self->{$k} = [ $self->{$k}, $v ];
    }
  }
}

sub delete {
  my ( $self, $param ) = @_;
  delete $self->{$param};
  my $aref = $self->{'pkit_parameters'} || return;
  for ( 0 .. $#$aref ) {
    next unless ( $param eq $aref->[$_] );
    splice @$aref, $_, 1;
    last;
  }
}

1;
