# -*- Perl -*-
#
# Toy deterministic separate chain hash implementation, based on code in
# "Algorithms (4th Edition)" by Robert Sedgewick and Kevin Wayne. This
# code is not for any sort of use where performance is critical, or
# where malicious input may cause "Algorithmic Complexity Attacks" (see
# perlsec(1)).
#
# Run perldoc(1) on this file for additional documentation.

package Algorithm::Toy::HashSC;

use 5.010;
use strict;
use warnings;

use Carp qw/croak/;
use Moo;
use namespace::clean;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.01';

##############################################################################
#
# ATTRIBUTES

# Each list should end up with ~N/M key-value pairs, assuming the input
# is not malicious, and that the hash function is perfect enough. "M"
# here is the modulus, and "N" is the number of key-value pairs added.
#
# Internally, it's an array of array of arrays, or something like that.
has _chain => (
  is      => 'rw',
  default => sub { [] },
);

has modulus => (
  is      => 'rw',
  default => sub { 7 },
  coerce  => sub {
    die 'modulus must be a positive integer > 1'
      if !defined $_[0]
      or !looks_like_number $_[0]
      or $_[0] < 2;
    return int $_[0];
  },
  trigger => sub {
    my ($self) = @_;
    # clobber extant hash (Moo does not provide old value, so cannot do
    # this only when the modulus changes, oh well)
    $self->_chain( [] ) unless $self->unsafe;
  },
);

# Boolean, disables various sanity checks if set to a true value (in
# particular whether the hash is cleared when the modulus is changed).
has unsafe => (
  is      => 'rw',
  default => sub { 0 },
  coerce  => sub { $_[0] ? 1 : 0 },
);

##############################################################################
#
# METHODS

sub clear_hash {
  my ($self) = @_;
  $self->_chain( [] );
  return $self;
}

sub get {
  my ( $self, $key ) = @_;
  croak "must provide key" if !defined $key;
  my $chain = $self->_chain->[ $self->hash($key) ];
  if ( defined $chain ) {
    for my $kvpair (@$chain) {
      return $kvpair->[1] if $key eq $kvpair->[0];
    }
  }
  return;
}

# Derives the index of the chain a particular key will be added to. The
# hashcode function, if available, should return something that ideally
# evenly distributes the given keys across the given modulus.
#
# Alternative: subclass this module and write yer own hash function.
sub hash {
  my ( $self, $key ) = @_;
  croak "must provide key" if !defined $key;
  my $code;
  if ( $key->can('hashcode') ) {
    $code = $key->hashcode();
  } else {
    # TODO is this adequate?
    for my $n ( map ord, split //, $key ) {
      $code += $n;
    }
  }
  return abs( $code % $self->modulus );
}

sub keys {
  my ($self) = @_;
  my @keys;
  for my $chain ( @{ $self->_chain } ) {
    push @keys, map { $_->[0] } @$chain;
  }
  return @keys;
}

sub keys_in {
  my ( $self, $index ) = @_;
  croak "must provide index" if !defined $index;
  $index %= $self->modulus;    # this will int() any floating-point nums
  return map { $_->[0] } @{ $self->_chain->[$index] };
}

# Keys in the same chain (or bucket) as a given key
sub keys_with {
  my ( $self, $key ) = @_;
  croak "must provide key" if !defined $key;
  for my $chain ( @{ $self->_chain } ) {
    for my $kvpair (@$chain) {
      return map $_->[0], @$chain if $key eq $kvpair->[0];
    }
  }
  return;
}

sub put {
  my ( $self, $key, $value ) = @_;
  croak "must provide key" if !defined $key;
  my $chain = $self->_chain->[ $self->hash($key) ];
  if ( defined $chain ) {
    for my $kvpair (@$chain) {
      if ( $key eq $kvpair->[0] ) {
        $kvpair->[1] = $value;
        return $self;
      }
    }
  }
  push @{ $self->_chain->[ $self->hash($key) ] }, [ $key, $value ];
  return $self;
}

# a.k.a. delete but more indicative of the obtaining-a-value aspect
sub take {
  my ( $self, $key ) = @_;
  croak "must provide key" if !defined $key;
  my $chain = $self->_chain->[ $self->hash($key) ];
  if ( defined $chain ) {
    for my $i ( 0 .. $#$chain ) {
      if ( $key eq $chain->[$i][0] ) {
        my $kvpair = splice @$chain, $i, 1;
        return $kvpair->[1];
      }
    }
  }
  return;
}

1;
__END__

##############################################################################
#
# DOCS

=head1 NAME

Algorithm::Toy::HashSC - toy separate chain hash implementation for Perl

=head1 SYNOPSIS

  use Algorithm::Toy::HashSC;
  my $h = Algorithm::Toy::HashSC->new;

  $h->put("key", "value");
  $h->get("key");           # "value"
  $h->put("blah", 42);
  $h->keys;                 # "key","blah" 
  $h->take("blah");         # 42
  $h->keys;                 # "key"

  # perhaps more interesting once more key/value pairs are added
  $h->keys_with("key")      # "key"

  # keys in a particular chain (from 0 to the modulus-1)
  $h->keys_in(0);

  # reset things
  $h->clear_hash;

  # change the number of chains (or buckets). this will destory
  # any prior contents of the hash
  $h->modulus(2);
  # or the modulus can be set via the constructor
  $h = Algorithm::Toy::HashSC->new( modulus => 2 );

  # Danger zone!
  $h->unsafe(1);

=head1 DESCRIPTION

A toy separate chain hash implementation; productive uses are left as an
exercise to the reader. (Hint: music or artwork where the particulars of
the hash code and modulus groups the data in a deterministic manner;
this ordering or grouping can help determine e.g. pitch sets, rhythmic
material, etc. Hence, the B<keys_in> and B<keys_with> methods to obtain
the keys in a chain, or with a particular key. Variety could be added by
varying the modulus, or changing the B<hash> or B<hashcode> methods.)

This module is not for use where performance is a concern, or where
untrusted user input may be supplied for the key material.
L<perlsec/"Algorithmic Complexity Attacks"> discusses why Perl's hash
are no longer deterministic.

=head1 CONSTRUCTOR

The B<new> method accepts any of the L</"ATTRIBUTES">.

=head1 ATTRIBUTES

=over 4

=item B<_chain>

Where the keys and values are stored. Internal value. No peeking!

=item B<modulus> I<an-integer-greater-than-one>

Gets or sets the B<modulus> attribute. This determines the number of
chains available. It probably should be a prime number (and must be
greater than one) to better help evenly distribute the keys. A smaller
B<modulus> will cause longer chains, that is, more keys and values
lumped together.

Setting this value will clear the contents of the hash (by default).

=item B<unsafe> I<boolean>

If set to a true value, will allow unsafe operations. Possible side-
effects include old keys and values lingering in the hash (use
B<clear_hash> if this is a problem) or keys and values not being
available, or to allow duplicate keys to be stored (depending on the
particulars of B<modulus> and the result of the B<hash> calculation).

(A caller could pass keys with a B<hashcode> method that violates the
B<unsafe> setting, but that's their problem (or feature).)

=back

=head1 METHODS

=over 4

=item B<clear_hash>

Clears the contents of the hash and returns the object.

The hash may also be cleared by default when various attributes
are altered.

=item B<get> I<key>

Obtains the value for the given I<key>. The key may be a scalar value,
or a coderef that provides a B<hashcode> method. Equality is tested for
via the C<eq> operator (L<perlop/"Equality Operators">).

Like B<take> but not destructive.

=item B<hash> I<key>

Used internally to calculate the index of the chain (or bucket) where
a given I<key> resides, within the limits of the B<modulus>
attribute. This calculation can be adjusted by supplying keys with a
B<hashcode> method.

=item B<keys>

Returns the keys present in the hash, if any. Keys are ordered based
on the structure of the hash chains, and this ordering will not
change unless the B<modulus> attribute or B<hash> or B<hashcode>
methods are altered.

=item B<keys_in> I<chain-number>

Returns the keys in the given I<chain-number> where I<chain-number> is
less than B<modulus>, if any.

=item B<keys_with> I<key>

Returns the keys in the same chain as the given key, if any. As with
B<keys>, this grouping will not change unless various attributes or
methods are altered. A smaller B<modulus> will cause more keys to
group together.

=item B<put> I<key> I<value>

Adds the given key and value to the hash. The I<key> may be an object
with a B<hashcode> method; this method should return a number that for
the expected set of key values results in evenly distributed numbers
across the given B<modulus>. If the key already exists in the hash, the
value will be updated.

=item B<take> I<key>

Deletes the given key/value pair from the hash, and returns the value. A
destructive version of B<get>.

=back

=head1 BUGS

=head2 Reporting Bugs

Bugs, patches, and whatnot might best be applied towards:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Toy-HashSC>

L<https://github.com/thrig/Algorithm-Toy-HashSC>

=head2 Known Issues

The default hash code calculation has not been tested to determine how
evenly it spreads keys out across the modulus space. As a workaround,
the hash key can be an object that provides a B<hashcode> method, in
which case this issue falls out of scope of this module.

=head1 SEE ALSO

L<perlsec/"Algorithmic Complexity Attacks"> - details on why Perl's hash
do not behave so simply as that of this module do.

"Algorithms" (4th Edition) by Robert Sedgewick and Kevin Wayne.

L<Hash::Util> - insight into Perl's hashes.

The "smhasher" project may help verify whether B<hashcode> functions are
as perfect as possible.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=cut
