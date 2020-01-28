package Data::Perl::Role::Collection::Hash;
$Data::Perl::Role::Collection::Hash::VERSION = '0.002011';
# ABSTRACT: Wrapping class for Perl's built in hash structure.

use strictures 1;

use Role::Tiny;
use Scalar::Util qw/blessed/;
use Module::Runtime qw/use_package_optimistically/;

sub new { my $cl = shift; bless({ @_ }, $cl) }

sub _array_class { 'Data::Perl::Collection::Array' }

sub get {
  my $self = shift;

  if (@_ > 1) {
    my @res = @{$self}{@_};

    blessed($self) ? use_package_optimistically($self->_array_class)->new(@res) : @res;
  }
  else {
    $self->{$_[0]};
  }
}

sub set {
  my $self = shift;
  my @keys_idx = grep { ! ($_ % 2) } 0..$#_;
  my @values_idx = grep { $_ % 2 } 0..$#_;

  @{$self}{@_[@keys_idx]} = @_[@values_idx];

  my @res = @{$self}{@_[@keys_idx]};

  blessed($self) ? use_package_optimistically($self->_array_class)->new(@res) : @res;
}

sub delete {
  my $self = shift;
  my @res = CORE::delete @{$self}{@_};

  blessed($self) ? use_package_optimistically($self->_array_class)->new(@res) : @res;
}

sub keys {
  my ($self) = @_;

  my @res = keys %{$self};

  blessed($self) ? use_package_optimistically($self->_array_class)->new(@res) : @res;
}

sub exists { CORE::exists $_[0]->{$_[1]} }

sub defined { CORE::defined $_[0]->{$_[1]} }

sub values {
  my ($self) = @_;

  my @res = CORE::values %{$_[0]};

  blessed($self) ? use_package_optimistically($self->_array_class)->new(@res) : @res;
}

sub kv {
  my ($self) = @_;

  my @res = CORE::map { [ $_, $self->{$_} ] } CORE::keys %{$self};

  blessed($self) ? use_package_optimistically($self->_array_class)->new(@res) : @res;
}


{
  no warnings 'once';

  sub all {
    my ($self) = @_;

    my @res = CORE::map { $_, $self->{$_} } CORE::keys %{$self};

    @res;
  }

  *elements = *all;
}

sub clear { %{$_[0]} = () }

sub count { CORE::scalar CORE::keys %{$_[0]} }

sub is_empty { CORE::scalar CORE::keys %{$_[0]} ? 0 : 1 }

sub accessor {
  if (@_ == 2) {
    $_[0]->{$_[1]};
  }
  elsif (@_ > 2) {
    $_[0]->{$_[1]} = $_[2];
  }
}

sub shallow_clone { blessed($_[0]) ? bless({%{$_[0]}}, ref $_[0]) : {%{$_[0]}} }

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Perl::Role::Collection::Hash - Wrapping class for Perl's built in hash structure.

=head1 VERSION

version 0.002011

=head1 SYNOPSIS

  use Data::Perl qw/hash/;

  my $hash = hash(a => 1, b => 2);

  $hash->values; # (1, 2)

  $hash->set('foo', 'bar'); # (a => 1, b => 2, foo => 'bar')

=head1 DESCRIPTION

This class provides a wrapper and methods for interacting with a hash.
All methods that return a list do so via a Data::Perl::Collection::Array
object.

=head1 PROVIDED METHODS

=over 4

=item B<new($key, $value, ...)>

Given an optional list of keys/values, constructs a new Data::Perl::Collection::Hash
object initalized with keys/values and returns it.

=item B<get($key, $key2, $key3...)>

Returns a list of values in the hash for the given keys.

This method requires at least one argument.

=item B<set($key =E<gt> $value, $key2 =E<gt> $value2...)>

Sets the elements in the hash to the given values. It returns the new values
set for each key, in the same order as the keys passed to the method.

This method requires at least two arguments, and expects an even number of
arguments.

=item B<delete($key, $key2, $key3...)>

Removes the elements with the given keys.

Returns a list of values in the hash for the deleted keys.

=item B<keys>

Returns the list of keys in the hash.

This method does not accept any arguments.

=item B<exists($key)>

Returns true if the given key is present in the hash.

This method requires a single argument.

=item B<defined($key)>

Returns true if the value of a given key is defined.

This method requires a single argument.

=item B<values>

Returns the list of values in the hash.

This method does not accept any arguments.

=item B<kv>

Returns the key/value pairs in the hash as an array of array references.

  for my $pair ( $object->option_pairs ) {
      print "$pair->[0] = $pair->[1]\n";
  }

This method does not accept any arguments.

=item B<elements/all>

Returns the key/value pairs in the hash as a flattened list..

This method does not accept any arguments.

=item B<clear>

Resets the hash to an empty value, like C<%hash = ()>.

This method does not accept any arguments.

=item B<count>

Returns the number of elements in the hash. Also useful for not empty:
C<< has_options => 'count' >>.

This method does not accept any arguments.

=item B<is_empty>

If the hash is populated, returns false. Otherwise, returns true.

This method does not accept any arguments.

=item B<accessor($key)>

=item B<accessor($key, $value)>

If passed one argument, returns the value of the specified key. If passed two
arguments, sets the value of the specified key.

When called as a setter, this method returns the value that was set.

=item B<shallow_clone>

This method returns a shallow clone of the hash reference.  The return value
is a reference to a new hash with the same keys and values.  It is I<shallow>
because any values that were references in the original will be the I<same>
references in the clone.

=item B<_array_class>

The name of the class which returned lists are instances of; i.e.
C<< Data::Perl::Collection::Array >>.

Subclasses of this class can override this method.

=back

Note that C<each> is deliberately omitted, due to its stateful interaction
with the hash iterator. C<keys> or C<kv> are much safer.

=head1 SEE ALSO

=over 4

=item * L<Data::Perl>

=item * L<MooX::HandlesVia>

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
==pod

