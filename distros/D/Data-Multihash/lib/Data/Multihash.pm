package Data::Multihash;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Set::Object qw(set);

our $VERSION = '0.03';

=head1 NAME

Data::Multihash - A hash table that supports multiple values per key.

=head1 SYNOPSIS

  use Data::Multihash;

  my $multihash = Data::Multihash->new();
  $multihash->insert(key => 'value', key => 'other_value');
  $multihash->insert(other_key => 'value');

  print 'There are ' . $multihash->size . ' elements in the multihash.';

=head1 DESCRIPTION

This module implements a multihash, which maps keys to sets of values.
Multihashes are unordered.

=head1 CONSTRUCTORS

=head2 new()

Create a new empty multihash.

=cut

sub new {
    bless {};
}

=head1 INSTANCE METHODS

=head2 insert(%pairs)

Insert key-value pairs.

=cut

sub insert {
    my ($self, %pairs) = @_;
    while (my ($k, $v) = each %pairs) {
        $self->{$k} = set() unless $self->{$k};
        $self->{$k}->insert($v);
    }
}

=head2 remove_key(@keys), remove_keys(@keys)

Remove all given keys and their values.

=cut

sub remove_key {
    my $self = shift;
    delete $self->{$_} for @_;
}

*remove_keys = \&remove_key;

=head2 remove_value(@values), remove_values(@values)

Remove all given values from the multihash.

=cut

sub remove_value {
    my $self = shift;
    for (keys %$self) {
        next unless exists $self->{$_};
        my $set = $self->{$_};
        $set->remove(@_);
        delete $self->{$_} unless $set->size;
    }
}

*remove_values = \&remove_value;

=head2 remove_pair(%pairs), remove_pairs(%pairs)

Remove all given (key, value) pairs from the multiset.

=cut

sub remove_pair {
    my ($self, %pairs) = @_;
    while (my ($k, $v) = each %pairs) {
        next unless exists $self->{$k};
        my $set = $self->{$k};
        $set->remove($v);
        delete $self->{$k} unless $set->size;
    }
}

*remove_pairs = \&remove_pair;

=head2 elements($key)

Return all elements associated with a key.

=cut

sub elements {
    my ($self, $key) = @_;
    $self->{$key} || set();
}

=head2 values

Return all values in the multihash as a list.

=cut

sub values {
    my $self = shift;
    my @sets = CORE::values %$self;
    map $_->elements, @sets;
}

=head2 size

Return the number of values in the multihash.

=cut

sub size {
    my $self = shift;
    my $result = 0;
    $result += $_->size for (CORE::values %$self);
    $result;
}

=head1 THREAD SAFETY

It is not safe to access a single multihash from multiple threads.

=head1 LICENSE

Copyright (c) 2014, Radek Slupik
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

=over

=item *

Redistributions of source code must retain the above copyright notice, this list
of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

=item *

Neither the name of  nor the names of its contributors may be used to    endorse
or promote products derived from this software without specific    prior written
permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
