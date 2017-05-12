use strict;
use warnings;

package Data::Couplet::Private;
BEGIN {
  $Data::Couplet::Private::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Couplet::Private::VERSION = '0.02004314';
}

# ABSTRACT: Private internal bits for Data::Couplet

# $Id:$
use Moose 0.90;
use MooseX::Types::Moose qw( :all );
use Carp;
use namespace::autoclean;
with('MooseX::Clone');



has '_ko' => (
  isa     => HashRef,
  is      => 'rw',
  default => sub { +{} },
  traits  => [qw( Clone Hash )],
  handles => {
    _ko_get      => 'get',
    _ko_set      => 'set',
    _ko_delete   => 'delete',
    _ko_keys     => 'keys',
    _ko_exists   => 'exists',
    _ko_defined  => 'defined',
    _ko_values   => 'values',
    _ko_kv       => 'kv',
    _ko_elements => 'elements',
    _ko_clear    => 'clear',
    _ko_count    => 'count',
    _ko_is_empty => 'is_empty',
  },
);


has '_kv' => (
  isa     => HashRef,
  is      => 'rw',
  default => sub { +{} },
  traits  => [qw( Clone Hash )],
  handles => {
    _kv_get      => 'get',
    _kv_set      => 'set',
    _kv_delete   => 'delete',
    _kv_keys     => 'keys',
    _kv_exists   => 'exists',
    _kv_defined  => 'defined',
    _kv_values   => 'values',
    _kv_kv       => 'kv',
    _kv_elements => 'elements',
    _kv_clear    => 'clear',
    _kv_count    => 'count',
    _kv_is_empty => 'is_empty',
  },
);


has '_ki' => (
  isa     => HashRef,
  is      => 'rw',
  default => sub { +{} },
  traits  => [qw( Clone Hash)],
  handles => {
    _ki_get      => 'get',
    _ki_set      => 'set',
    _ki_delete   => 'delete',
    _ki_keys     => 'keys',
    _ki_exists   => 'exists',
    _ki_defined  => 'defined',
    _ki_values   => 'values',
    _ki_kv       => 'kv',
    _ki_elements => 'elements',
    _ki_clear    => 'clear',
    _ki_count    => 'count',
    _ki_is_empty => 'is_empty',
  },
);


has '_ik' => (
  isa     => ArrayRef,
  is      => 'rw',
  default => sub { [] },
  traits  => [qw( Clone Array )],
  handles => {
    _ik_count         => 'count',
    _ik_is_empty      => 'is_empty',
    _ik_elements      => 'elements',
    _ik_get           => 'get',
    _ik_pop           => 'pop',
    _ik_push          => 'push',
    _ik_shift         => 'shift',
    _ik_unshift       => 'unshift',
    _ik_splice        => 'splice',
    _ik_first         => 'first',
    _ik_grep          => 'grep',
    _ik_map           => 'map',
    _ik_reduce        => 'reduce',
    _ik_sort          => 'sort',
    _ik_sort_in_place => 'sort_in_place',
    _ik_shuffle       => 'shuffle',
    _ik_uniq          => 'uniq',
    _ik_join          => 'join',
    _ik_set           => 'set',
    _ik_delete        => 'delete',
    _ik_insert        => 'insert',
    _ik_clear         => 'clear',
  },
);


sub _object_to_key {
  my ( $self, $object ) = @_;
  my $key;
  if ( not defined $object ) {
    Carp::croak('Cant Stringify Undef for use as a key.');
  }
  $key = "$object";
  return $key;
}


sub _unset_at {
  my ( $self, $index ) = @_;
  $self->_ik_splice( $index, 1, () );
  return $self;
}


sub _unset_key {
  my ( $self, $key ) = @_;

  # Forget Where
  $self->_ki_delete($key);

  # Forget What it is
  $self->_ko_delete($key);

  # Forget what it means
  $self->_kv_delete($key);

  return $self;
}


sub _move_key_range {
  my ( $self, $start, $stop, $amt ) = @_;
  for ( $start .. $stop ) {
    my $indexk = $self->_ik_get($_);
    $self->_ki_set( $indexk, $self->_ki_get($indexk) + $amt );
  }
  return $self;
}


sub _index_key {
  my ( $self, $key ) = @_;
  if ( $self->_ki_exists($key) ) {
    return $self->_ki_get($key);
  }
  my $index = ( $self->_ik_push($key) - 1 );
  $self->_ki_set( $key, $index );
  return $index;
}


sub _set {
  my ( $self, $object, $value ) = @_;
  my $key = $self->_object_to_key($object);
  $self->_set_kiov( $key, $self->_index_key($key), $object, $value );
  return $self;
}


sub _set_kiov {
  my ( $self, $k, $i, $o, $v ) = @_;
  $self->_ki_set( $k, $i );
  $self->_ko_set( $k, $o );
  $self->_kv_set( $k, $v );
  return $self;
}


sub _sync_ki {
  my ($self) = @_;
  $self->_ki_clear();
  my $i = 0;
  for ( $self->_ik_elements ) {
    $self->_ki_set( $_, $i );
    $i++;
  }
  return $self;
}


sub _sync_ik {
  my ($self) = @_;

  my @pp = $self->_ki_kv;

  $self->_ik_clear();
  $self->_ki_clear();

  # Sort by values, that is, their indices.

  @pp = sort { $a->[1] <=> $b->[1] } @pp;

  while (@pp) {
    my $kv = shift @pp;
    $self->_index_key( $kv->[0] );
  }
  return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

Data::Couplet::Private - Private internal bits for Data::Couplet

=head1 VERSION

version 0.02004314

=head1 SYNOPSIS

This class contains all the private stuff Data::Couplet uses.

This arrangement is somewhat experimental, but its benefits are as follows

=over 4

=item - Publicly Readable Private Documentation

Ensures that other people hacking on internals have plenty to work with

=item - Private Documentation Separate from Public

Ensures end users don't get weighed down and tempted by stuff they don't need.

=item - Separation of Concerns

Separates logically the interface from the implementation, allowing for more
disperse changes without worry about breaking things.

=back

The above structure could also be reverted back to something more sane, but you
shouldn't mind, you don't rely on private methods anyway, do you? :)

=head1 ATTRIBUTES

These might change yet from a hash quad to something simpler, like

    [  k, k, k, ]
    { k => [ i, k, v ], k => [ i, k, v ] }

=head2 _ko : rw HashRef

Stores a mapping of Keys to Objects.

    { KEY_SCALAR => $KEY_OBJECT }

This is our internal way of mapping scalar representations of objects back to the objects.
NB: Because of how the conversion to scalar works at present, if an object is used for a key that
has string overload, the overloaded value will be used in the index.

=head2 _kv : rw HashRef

Stores a mapping of Keys to Values

    { KEY_SCALAR => $VALUE_OBJECT }

This is our primary data store, unordered, this is the part of the data that directly represents
what you would get with a normal hash.

=head2 _ki : rw HashRef

Stored a mapping of Keys to Indexes.

    { KEY_SCALAR => $INDEX_SCALAR }

This is required if you need to know where in an array a key is without having
to search the array for it. It also makes data set reordering
much easier, increment values :)

=head2 _ik : rw ArrayRef

This keeps our keys in order

    [ KEY_SCALAR , KEY_SCALAR ]

=head1 METHODS

=head2 ->_object_to_key ( $object ) : String

 Maps Anything to a usable Key.
 Essentially, stringify.
 This is done this way in case we need to change it later

=head2 ->_unset_at ( Int $index ) : $self : Modifier

 Deletes things that are found using an index only.

=head2 ->_unset_key ( String $key ) : $self : Modifier

 Deletes things that are found using a key only

=head2 ->_move_key_range( Int $left , Int $right , Int $jump ) : $self : Modifier

 Move a set of keys in the hash
 by $amt in $sign direction
 ->_move_key_range( $start, $stop , -1 ); # move left
 ->_move_key_range( $start, $stop , +1 ); # move right

=head2 ->_index_key ( String $key ) : Int : Modifier

Given a key, asserts it is in the data set, either by finding it
or by creating it. Returns where the key is.

=head2 ->_set ( Any $object , Any $value ) : $self : Modifier

Insertion is easy. Everything that inserts the easy way
can call this.

=head2 ->_set_kiov ( String $key , Int $index, Any $object , Any $value ) : $self : Modifier

Handles the part of assigning all the Key => Value association needed in many parts.

=head2 ->_sync_ki : $self : Modifier

Assume _ki is dead, and _ik is in charge, rebuild
_ki from _ik

=head2 ->_sync_ik : $self : Modifier

Assume _ik is dead, and _ki is in charge,
rebuild _ik from _ki

=head1 AUTHOR

Kent Fredric <kentnl at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

