package Data::Dict;

use strict;
use warnings;
use Carp ();
use Exporter 'import';

our $VERSION = '0.003';

our @EXPORT_OK = 'd';

my $MC;
sub _load_mc {
  local $@;
  return $MC = !!eval { require Mojo::Collection; 1 };
}

sub d { __PACKAGE__->new(@_) }

sub new {
  my $class = shift;
  return bless {@_}, ref $class || $class;
}

sub TO_JSON { +{%{$_[0]}} }

sub delete {
  my $self = shift;
  my @values = CORE::delete @$self{@_};
  return $self->new(CORE::map { ($_[$_], $values[$_]) } 0..$#_);
}

sub each {
  my ($self, $cb) = @_;
  return CORE::map { [$_, $self->{$_}] } CORE::keys %$self unless $cb;
  $cb->($_, $self->{$_}) for CORE::keys %$self;
  return $self;
}

sub each_c {
  Carp::croak 'Mojo::Collection is required for each_c' unless defined $MC ? $MC : _load_mc;
  my $self = shift;
  return Mojo::Collection->new(CORE::map { Mojo::Collection->new($_, $self->{$_}) } CORE::keys %$self);
}

sub each_sorted {
  my ($self, $cb) = @_;
  return CORE::map { [$_, $self->{$_}] } sort +CORE::keys %$self unless $cb;
  $cb->($_, $self->{$_}) for sort +CORE::keys %$self;
  return $self;
}

sub each_sorted_c {
  Carp::croak 'Mojo::Collection is required for each_sorted_c' unless defined $MC ? $MC : _load_mc;
  my $self = shift;
  return Mojo::Collection->new(CORE::map { Mojo::Collection->new($_, $self->{$_}) } sort +CORE::keys %$self);
}

sub extract {
  my ($self, $cb) = @_;
  my @keys = ref $cb eq 'Regexp'
    ? CORE::grep { m/$cb/ } CORE::keys %$self
    : CORE::grep { $cb->($_, $self->{$_}) } CORE::keys %$self;
  my @values = CORE::delete @$self{@keys};
  return $self->new(CORE::map { ($keys[$_], $values[$_]) } 0..$#keys);
}

sub grep {
  my ($self, $cb) = @_;
  return $self->new(CORE::map { ($_, $self->{$_}) } CORE::grep { m/$cb/ } CORE::keys %$self) if ref $cb eq 'Regexp';
  return $self->new(CORE::map { ($_, $self->{$_}) } CORE::grep { $cb->($_, $self->{$_}) } CORE::keys %$self);
}

sub keys {
  my ($self, $cb) = @_;
  return CORE::keys %$self unless $cb;
  $cb->($_) for CORE::keys %$self;
  return $self;
}

sub keys_c {
  Carp::croak 'Mojo::Collection is required for keys_c' unless defined $MC ? $MC : _load_mc;
  my $self = shift;
  return Mojo::Collection->new(CORE::keys %$self);
}

sub map {
  my ($self, $cb) = @_;
  return CORE::map { $cb->($_, $self->{$_}) } CORE::keys %$self;
}

sub map_c {
  Carp::croak 'Mojo::Collection is required for map_c' unless defined $MC ? $MC : _load_mc;
  my ($self, $cb) = @_;
  return Mojo::Collection->new(CORE::map { $cb->($_, $self->{$_}) } CORE::keys %$self);
}

sub map_sorted {
  my ($self, $cb) = @_;
  return CORE::map { $cb->($_, $self->{$_}) } sort +CORE::keys %$self;
}

sub map_sorted_c {
  Carp::croak 'Mojo::Collection is required for map_sorted_c' unless defined $MC ? $MC : _load_mc;
  my ($self, $cb) = @_;
  return Mojo::Collection->new(CORE::map { $cb->($_, $self->{$_}) } sort +CORE::keys %$self);
}

sub size { scalar CORE::keys %{$_[0]} }

sub slice {
  my $self = shift;
  return $self->new(CORE::map { ($_, $self->{$_}) } @_);
}

sub tap {
  my ($self, $cb) = (shift, shift);
  $_->$cb(@_) for $self;
  return $self;
}

sub to_collection {
  Carp::croak 'Mojo::Collection is required for to_collection' unless defined $MC ? $MC : _load_mc;
  return Mojo::Collection->new(%{$_[0]});
}

sub to_collection_sorted {
  Carp::croak 'Mojo::Collection is required for to_collection_sorted' unless defined $MC ? $MC : _load_mc;
  my $self = shift;
  return Mojo::Collection->new(CORE::map { ($_, $self->{$_}) } sort +CORE::keys %$self);
}

sub to_hash { +{%{$_[0]}} }

sub transform {
  my ($self, $cb) = @_;
  return $self->new(CORE::map { $cb->($_, $self->{$_}) } CORE::keys %$self);
}

sub values {
  my ($self, $cb) = (shift, shift);
  return CORE::values %$self unless $cb;
  $_->$cb(@_) for CORE::values %$self;
  return $self;
}

sub values_c {
  Carp::croak 'Mojo::Collection is required for values_c' unless defined $MC ? $MC : _load_mc;
  my $self = shift;
  return Mojo::Collection->new(CORE::values %$self);
}

1;

=head1 NAME

Data::Dict - Hash-based dictionary object

=head1 SYNOPSIS

  use Data::Dict;

  # Manipulate dictionary
  my $dictionary = Data::Dict->new(a => 1, b => 2, c => 3);
  delete $dictionary->{b};
  print join "\n", $dictionary->keys;

  # Chain methods
  $dictionary->slice(qw(a b))->grep(sub { defined $_[1] })->each(sub {
    my ($key, $value) = @_;
    print "$key: $value\n";
  });

  # Use the alternative constructor
  use Data::Dict 'd';
  use experimental 'signatures';
  my $num_highest = d(%counts)->transform(sub ($k, $v) { ($k, $v+1) })->grep(sub ($k, $v) { $v > 5 })->size;

  # Use Mojo::Collection for more chaining
  d(%hash)->map_sorted_c(sub { join ':', @_ })->shuffle->join("\n")->say;

=head1 DESCRIPTION

L<Data::Dict> is a hash-based container for dictionaries, with heavy
inspiration from L<Mojo::Collection>. Unless otherwise noted, all methods
iterate through keys and values in default keys order, which is random but
consistent until the hash is modified.

  # Access hash directly to manipulate dictionary
  my $dict = Data::Dict->new(a => 1, b => 2, c => 3);
  $dict->{b} += 100;
  print "$_\n" for values %$dict;

=head1 FUNCTIONS

=head2 d

  my $dict = d(a => 1, b => 2);

Construct a new hash-based L<Data::Dict> object. Exported on demand.

=head1 METHODS

=head2 new

  my $dict = Data::Dict->new(a => 1, b => 2);

Construct a new hash-based L<Data::Dict> object.

=head2 TO_JSON

Alias for L</"to_hash">.

=head2 delete

  my $deleted = $dict->delete(@keys);

Delete selected keys from the dictionary and return a new dictionary containing
the deleted keys and values.

=head2 each

  my @pairs = $dict->each;
  $dict     = $dict->each(sub {...});

Evaluate callback for each pair in the dictionary, or return pairs as list of
key/value arrayrefs if none has been provided. The callback will receive the
key and value as arguments.

  $dict->each(sub {
    my ($key, $value) = @_;
    print "$key: $value\n";
  });

  # values can be modified in place
  $dict->each(sub { $_[1] = $_[0]x2 });

=head2 each_c

  my $collection = $dict->each_c;

Create a new collection of key/value pairs as collections. Requires
L<Mojo::Collection>.

  # print all keys and values
  print $dict->each_c->flatten->join(' ');

=head2 each_sorted

  my @pairs = $dict->each_sorted;
  $dict     = $dict->each_sorted(sub {...});

As in L</"each">, but the pairs are returned or the callback is called in
sorted keys order.

=head2 each_sorted_c

  my $collection = $dict->each_sorted_c;

As in L</"each_c">, but the pairs are added to the collection in sorted keys
order. Requires L<Mojo::Collection>.

=head2 extract

  my $extracted = $dict->extract(qr/foo/);
  my $extracted = $dict->extract(sub {...});

Evaluate regular expression on each key, or call callback on each key/value
pair in the dictionary, and remove all pairs that matched the regular
expression, or for which the callback returned true. Return a new dictionary
with the removed keys and values. The callback will receive the key and value
as arguments.

  my $high_numbers = $dict->extract(sub { $_[1] > 100 });

=head2 grep

  my $new = $dict->grep(qr/foo/);
  my $new = $dict->grep(sub {...});

Evaluate regular expression on each key, or call callback on each key/value
pair in the dictionary, and return a new dictionary with all pairs that matched
the regular expression, or for which the callback returned true. The callback
will receive the key and value as arguments.

  my $banana_dict = $dict->grep(qr/banana/);

  my $fruits_dict = $dict->grep(sub { $_[1]->isa('Fruit') });

=head2 keys

  my @keys = $dict->keys;
  $dict    = $dict->keys(sub {...});

Evaluate callback for each key in the dictionary, or return all keys as a list
if none has been provided. The key will be the first argument passed to the
callback, and is also available as C<$_>.

=head2 keys_c

  my $collection = $dict->keys_c;

Create a new collection from all keys. Requires L<Mojo::Collection>.

  my $first_key = $dict->keys_c->first;

=head2 map

  my @results = $dict->map(sub {...});

Evaluate callback for each key/value pair in the dictionary and return the
results as a list. The callback will receive the key and value as arguments.

  my @pairs = $dict->map(sub { [@_] });

  my @values = $dict->map(sub { $_[1] });

=head2 map_c

  my $collection = $dict->map_c(sub {...});

Evaluate callback for each key/value pair in the dictionary and create a new
collection from the results. The callback will receive the key and value as
arguments. Requires L<Mojo::Collection>.

  my $output = $dict->map_c(sub { "$_[0]: $_[1]" })->join("\n");

=head2 map_sorted

  my @results = $dict->map_sorted(sub {...});

As in L</"map">, but the callback is evaluated in sorted keys order.

=head2 map_sorted_c

  my $collection = $dict->map_sorted_c(sub {...});

As in L</"map_c">, but the callback is evaluated in sorted keys order. Requires
L<Mojo::Collection>.

=head2 size

  my $size = $dict->size;

Number of keys in dictionary.

=head2 slice

  my $new = $dict->slice(@keys);

Create a new dictionary with all selected keys.

  print join ' ', d(a => 1, b => 2, c => 3)->slice('a', 'c')
    ->map_sorted(sub { join ':', @_ }); # a:1 c:3

=head2 tap

  $dict = $dict->tap(sub {...});

Perform callback and return the dictionary object for further chaining, as in
L<Mojo::Base/"tap">. The dictionary object will be the first argument passed to
the callback, and is also available as C<$_>.

=head2 to_collection

  my $collection = $dict->to_collection;

Turn dictionary into even-sized collection of keys and values. Requires
L<Mojo::Collection>.

=head2 to_collection_sorted

  my $collection = $dict->to_collection_sorted;

Turn dictionary into even-sized collection of keys and values in sorted keys
order. Requires L<Mojo::Collection>.

=head2 to_hash

  my $hash = $dict->to_hash;

Turn dictionary into hash reference.

=head2 transform

  my $new = $dict->transform(sub {...});

Evaluate callback for each key/value pair in the dictionary and create a new
dictionary from the returned keys and values (assumed to be an even-sized
key/value list). The callback will receive the key and value as arguments.

  my $reversed = $dict->transform(sub { ($_[1], $_[0]) });

  my $doubled = $dict->transform(sub {
    my ($k, $v) = @_;
    return ($k => $v, ${k}x2 => $v);
  });

=head2 values

  my @values = $dict->values;
  $dict      = $dict->values(sub {...});

Evaluate callback for each value in the dictionary, or return all values as a
list if none has been provided. The value will be the first argument passed to
the callback, and is also available as C<$_>.

  # values can be modified in place
  $dict->values(sub { $_++ });

=head2 values_c

  my $collection = $dict->values_c;

Create a new collection from all values. Requires L<Mojo::Collection>.

  my @shuffled_values = $dict->values_c->shuffle->each;

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Collection>
