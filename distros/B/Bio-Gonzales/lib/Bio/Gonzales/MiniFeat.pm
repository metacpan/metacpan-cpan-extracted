package Bio::Gonzales::MiniFeat;
use strict;
use warnings;
use Carp;

use Mouse;
use List::MoreUtils qw/zip/;
use Data::Dumper;
use Storable qw(dclone);
use Scalar::Util qw/refaddr/;

our $QUIET_MODE;

our $VERSION = '0.0546'; # VERSION

has [qw/source type/] => ( is => 'rw', required => 1 );

has attributes => ( is => 'rw', default => sub { {} } );

has [qw/subfeats parentfeats/] => ( is => 'rw', default => sub { [] } );

sub attr { return shift->attributes(@_); }

sub clone {
  my ($self) = @_;

  my %data = %$self;
  $data{attributes} = dclone( $data{attributes} ) if ( exists( $data{attributes} ) );

  return __PACKAGE__->new( \%data );
}

sub _attr_single {
  my ( $self, $p ) = @_;
  $p = { name => $p } unless ( ref $p );

  confess "no attributes can be set with this method" if ( $p->{args} );
  return
    unless ( exists( $self->attributes->{ $p->{name} } ) && @{ $self->attributes->{ $p->{name} } } > 0 );
  carp "multiple ID entries, taking the first"
    if ( @{ $self->attributes->{ $p->{name} } } > 1 && !$p->{quiet} );
  return $self->attributes->{ $p->{name} }[0];
}

sub _attr_list {
  my ( $self, $attr, @values ) = @_;

  return
    unless ( exists( $self->attributes->{$attr} ) && @{ $self->attributes->{$attr} } > 0 );

  return wantarray ? @{ $self->attributes->{$attr} } : $self->attributes->{$attr}
    unless ( @values && @values > 0 );

  my $current_v = $self->attributes->{$attr};
  my $new_v;
  if ( @values == 1 && ref $values[0] eq 'ARRAY' ) {
    $self->attributes->{$attr} = $values[0];
  } else {
    $self->attributes->{$attr} = \@values;

  }
  return wantarray ? @{$current_v} : $current_v;
}

sub first_attr {
  my ( $self, $name ) = @_;
  return $self->_attr_single( { name => $name, quiet => 1 } );
}

sub attr_first { return shift->first_attr(@_); }

sub id { return shift->_attr_single( { name => 'ID' } ); }

sub ids { return shift->_attr_list('ID', @_); }

sub attr_list { return shift->_attr_list(shift); }

sub name { return shift->_attr_single( { name => 'Name' } ); }

sub parent_ids { return shift->_attr_list('Parent', @_); }

sub parent_id { return shift->_attr_single( { name => 'Parent' } ); }

sub replace_attr {
  my ( $self, $name, @values ) = @_;

  confess "name cannot be a reference" if(ref $name);
  return $self->_attr_list($name, \@values);
}

sub parents {
  confess 'use parent_ids';
}

sub parent {
  confess 'use parent_id';
}

sub recurse_subfeats {
  my ( $self, $sub ) = @_;

  $sub = sub { return $_[0] }
    unless defined $sub;

  my %visited;
  return $self->_recurse_subfeats( \%visited, $sub, 1 );

}

sub _recurse_subfeats {
  my ( $self, $v, $sub, $depth ) = @_;

  if ( exists( $v->{ refaddr($self) } ) && $v->{ refaddr($self) } != $depth ) {
    confess "Recursion in subfeature retrieval in level $depth/"
      . $v->{ refaddr($self) } . "\n"
      . Dumper $self;
  }

  $v->{ refaddr($self) } = $depth;

  my @result;
  if ( @{ $self->subfeats } > 0 ) {
    $depth++;
    for my $sf ( @{ $self->subfeats } ) {
      push @result, $sub->( $sf, $depth );
      push @result, $sf->_recurse_subfeats( $v, $sub, $depth );
    }
  }

  return @result;
}

sub uniq {
  my ($self) = @_;

  $self->subfeats(    [ List::MoreUtils::uniq @{ $self->subfeats } ] );
  $self->parentfeats( [ List::MoreUtils::uniq @{ $self->parentfeats } ] );
}

sub add_attr {
  my ( $self, %attrs ) = @_;

  while ( my ( $name, $value ) = each %attrs ) {
    $self->attributes->{$name} = [] unless defined $self->attributes->{$name};
    push @{ $self->attributes->{$name} }, ( ref $value eq 'ARRAY' ? @$value : $value );
  }

  return;
}

sub has_attr {
  my ( $self, $name ) = @_;
  return exists( $self->attributes->{$name} );
}

sub del_attr {
  my ( $self, @names ) = @_;

  my @deleted;
  for my $name (@names) {
    push @deleted, delete $self->attributes->{$name};
  }
  return @names == 1 ? $deleted[0] : \@deleted;
}

1;
