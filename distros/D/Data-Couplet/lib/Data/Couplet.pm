use strict;
use warnings FATAL => 'all';

package Data::Couplet;
BEGIN {
  $Data::Couplet::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Couplet::VERSION = '0.02004314';
}

# ABSTRACT: Yet another (But Hopefully Better) Key-Value Storage mechanism

use Data::Couplet::Extension -base => 'Private', -with => [qw( KeyCount BasicReorder )];
use MooseX::Types::Moose qw( :all );
use Carp;
use namespace::autoclean;

with( 'MooseX::Clone', );






sub BUILDARGS {
  my @args  = @_;
  my $class = shift @args;
  if ( scalar @args & 1 ) {
    Carp::croak('Uneven list sent. ERROR: Must be an ordered array that simulates a hash [k,v,k,v]');
  }

  my $c = Data::Couplet::Private->new();
  while (@args) {
    $c->_set( shift @args, shift @args );
  }
  return { %{$c} };
}



sub set {
  my ( $self, $object, $value ) = @_;
  $self->_set( $object, $value );
  return $self;
}



sub unset {
  my ( $self, @objects ) = @_;
  foreach my $object (@objects) {
    $self->unset_key( $self->_object_to_key($object) );
  }
  return $self;
}


sub __all_int {
  my (@items) = @_;
  for ( 0 .. $#items ) {
    my $v = $items[$_];
    carp("Token $_ is not an Int: $v ") unless is_Int($v);
  }
  return 1;
}

sub __all_str {
  my (@items) = @_;
  for ( 0 .. $#items ) {
    my $v = $items[$_];
    carp("Token $_ is not a Str: $v ") unless is_Str($v);
  }
  return 1;
}

sub unset_at {
  my ( $self, @indices ) = @_;
  __all_int(@indices);
  @indices = sort { $a <=> $b } @indices;
  @indices = grep {
    $self->key_at($_) ? 1 : do {
      Carp::carp("Warning: index $_ does not exist already");
      0;
      }
  } @indices;
  my $unset = 0;
  foreach my $index (@indices) {
    my $fake_index = ( $index - $unset );
    my $key        = $self->key_at($fake_index);
    if ( not defined $key ) {
      Carp::carp("Cant delete index $index($fake_index), it has no key.");
    }
    else {
      $self->unset_key($key);
    }
    $unset++;
  }
  return $self;
}


sub unset_key {
  my ( $self, @keys ) = @_;
  __all_str(@keys);
  foreach my $key (@keys) {

    #Skip any keys that aren't set
    next unless ( exists $self->{_kv}->{$key} );
    my $index = $self->{_ki}->{$key};
    $self->_unset_at($index);
    $self->_unset_key($key);
    $self->_move_key_range( $index, $#{ $self->{_ik} }, 0 - 1 );
  }
  return $self;
}



sub value {
  my ( $self, $object ) = @_;
  my $key = $self->_object_to_key($object);
  return $self->{_kv}->{$key};
}


sub value_at {
  my ( $self, $index ) = @_;
  __all_int($index);
  my $key = $self->{_ik}->[$index];
  return $self->{_kv}->{$key};
}


sub values {
  my ($self) = @_;
  return map { $self->{_kv}->{$_} } @{ $self->{_ik} };
}


sub values_ref {
  my ( $self, @args ) = @_;
  return [ $self->values(@args) ];
}


sub key_values {
  my ($self) = @_;
  return map { ( $self->{_ko}->{$_}, $self->{_kv}->{$_} ) } @{ $self->{_ik} };
}


sub key_values_paired {
  my ($self) = @_;
  return map { [ $self->{_ko}->{$_}, $self->{_kv}->{$_} ] } @{ $self->{_ik} };
}



sub keys {
  my ($self) = @_;
  return map { $self->key_object($_) } @{ $self->{_ik} };
}


sub key_at {
  my ( $self, $index ) = @_;
  __all_int($index);
  return $self->{_ik}->[$index];
}


sub key_object {
  my ( $self, $key ) = @_;
  __all_str($key);
  return $self->{_ko}->{$key};
}


sub key_object_at {
  my ( $self, $index ) = @_;
  __all_int($index);
  return $self->{_ko}->{ $self->key_at($index) };
}


no Data::Couplet::Extension;
__PACKAGE__->meta->make_immutable();
1;


__END__
=pod

=head1 NAME

Data::Couplet - Yet another (But Hopefully Better) Key-Value Storage mechanism

=head1 VERSION

version 0.02004314

=head1 SYNOPSIS

  use Data::Couplet;

  # Retain order.
  my $couplet = Data::Couplet->new(   a => $b , c => $d );

  my $output = $couplet->value('a');  # returns $b;

  my $hash = { 'this is a' => 'key' };

  $couplet->set( $hash, "hello");
  $couplet->value( $hash ); # hello

=head1 ALPHA CODE

Lots of stuff is probably still broken, unimplemented, untested.

User beware

=head1 DIFFERENT

Why is this module different?

=over 4

=item 1. No Tied Hashes.

Tied hashes are IMO Ugly. Objects are far more handy for many things. Especially
in moose world. You want tied hashes, do it yourself.

=item 2. Trying Hard to preserve non-scalar keys.

I want it to be possible, to retain arbitrary references used as keys.

=item 3. Permutation.

Its not here yet, but there I<Will> eventually be reordering functions.

=back

I seriously looked all over CPAN for something that suited my needs and didn't find any.

I then tried with Tie::IxHash::ButMoreFun, and then discovered that how I was
using Tie::IxHash wasn't even sustainable on different versions of Perl, and
based on the 1997 release date, I gave up on seeing that fixed.

=head1 METHODS

=head2 CONSTRUCTOR

=head3 ->new( %orderd_pairs )

Create a new Data::Couplet entity using a series of ordered pairs.

  $c = Data::Couplet->new( 'a' => 'b', 'c' => 'd' );

=head2 ENTRY CREATION

=head3 ->set( Any $object, Any  $value ) : $self : Modifier

Record the association of a key ( any object that can be coerced into a string )  to a value.

New entries are pushed on the logical right hand end of it in array context.

  # { 'a' => 'b', 'c' => 'd' }
  set( 'a', 'e' );
  # { 'a' => 'e', 'c' => 'd' }
  set('e', 'a' );
  # { 'a' => 'e', 'c' => 'd', 'e' => 'a' }

=head2 ENTRY REMOVAL

=head3 ->unset( Array[Any] @objects ) : $self : Modifier

Entries are ripped out of the structure, and all items moved around to fill the void.

  # { 'a' => 'b', 'c' => 'd','e'=>'f' }
  ->unset( 'c' );
  # { 'a' => 'b', 'e'=>'f' }
  ->unset('a');
  # { 'e' => 'f' }

=head3 ->unset_at( Array[Int] @indices ) : $self : Modifier

Like ->unset, except you know where ( logically ) in the order
off things the entry you wish to delete is.

  ->unset_at( 1 );
  ->unset_at( 0 );

Should be identical to the above code.

=head3 ->unset_key( Array[Str] @keys ) : $self : Modifier

This is what ->unset ultimately calls, except ->unset does implicit
object_to_key conversion first. At present, that's not anything huge, its just
C<$object> to convert it to a string. But this may change at some future time. So use that
method instead.

=head2 VALUE MANIPULATION

=head3 ->value( Any $object ) : Any $value

Returns a value associated with a key object. See L</unset> for the semantics
of what object keys are.

=head3 ->value_at( Int $index ) : Any $value

Like value, but you need to know where in the data set the item is.

=head3 ->values() : Any @list

returns an array of all stored values in order.

=head3 ->values_ref() : ArrayRef[Any] $list

Just some nice syntax for [$o->values]

=head3 ->key_values() : Any @list

Returns an ordered sequence of key,value pairs, just like that passed
to the constructor.

  my @d = $o->key_values()
  while( @d ){
    my $key = shift @d;
    my $value = shift @d;
    print "$key => $value\n"
  }

=head3 ->key_values_paired() : Any[ArrayRef] @list

Returns like ->key_values does but key/value is grouped for your convenience

  for ( $o->key_values_paired() ){
    my ( $key, $value ) = @{ $_ };
  }

=head2 KEY MANIPULATION

=head3 ->keys() : @list

returns all known keys in order

=head3 ->key_at( Int $index ) : String

Given an index, return the key that holds that place.

=head3 ->key_object( String $key ) : Any $object

Given a string key, returns the object stored there.

This is probably very unhelpful to you unless you explicitly
asked us for our internal key name.

=head3 ->key_object_at( Int $index ) : Any $object

As with key_object, except partially useful, because you can fetch
by ID.

=head2 METHODS FROM PLUGINS

By default, this package imports a few methods from various plug-ins.

=over 4

=item * L<Data::Couplet::Plugin::KeyCount>

=over 4

=item ->count

=item ->last_index

=item ->indices

=back

=item * L<Data::Couplet::Plugin::BasicReorder>

=over 4

=item ->move_up

=item ->move_down

=item ->swap

=back

=back

=head1 AUTHOR

Kent Fredric <kentnl at cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

