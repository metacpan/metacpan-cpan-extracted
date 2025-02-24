package Data::NestedKey;

# This module provides an object-oriented way to manipulate deeply nested hash
# structures using dot-separated keys, with flexible serialization options.

use strict;
use warnings;

use Carp;
use Data::Dumper;
use JSON;
use List::Util qw(pairs);
use Scalar::Util qw(reftype);
use Storable qw(nfreeze);
use YAML ();  # Load YAML support

our $VERSION = '0.06';

# Package variables for serialization options
our $JSON_PRETTY = 1;       # Controls whether JSON output is pretty or compact
our $FORMAT      = 'JSON';  # Default serialization format

use overload '""' => \&as_string;

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $init_data = ref $args[0] ? shift @args : {};
  my @kv_list   = @args;

  # If the first argument is a hash reference, use it; otherwise, start with an empty structure
  my $self = bless { data => _is_hash($init_data) ? $init_data : {} }, $class;

  # If $init_data wasn't a hash ref, treat it as a key-value pair
  if ( !_is_hash($init_data) ) {
    @kv_list = ( $init_data, @kv_list );
  }

  # Short-circuit if no key-value pairs are provided
  return $self
    if !@kv_list;

  # Ensure key-value pairs are valid
  croak 'Must provide key-value pairs'
    if @kv_list && @kv_list % 2 != 0;

  # Populate the structure using `set`
  $self->set(@kv_list);

  return $self;
}

########################################################################
sub _is_array { return ref $_[0] && reftype( $_[0] ) eq 'ARRAY'; }
########################################################################

########################################################################
sub _is_hash { return ref $_[0] && reftype( $_[0] ) eq 'HASH'; }
########################################################################

########################################################################
sub set {
########################################################################
  my ( $self, @kv_list ) = @_;
  croak 'Must provide key-value pairs' if @kv_list % 2 != 0;

  for my $p ( pairs @kv_list ) {
    my ( $key_path, $value ) = @{$p};
    my $action = $key_path =~ s/^([+-])// ? $1 : q{};

    my @keys    = split /[.]/, $key_path;
    my $current = $self->{data};

    for my $key ( @keys[ 0 .. $#keys - 1 ] ) {
      $current->{$key} //= {};
      $current = $current->{$key};
    }

    my $final_key = $keys[-1];

    if ( $action eq q{+} ) {
      if ( _is_array( $current->{$final_key} ) ) {
        push @{ $current->{$final_key} }, $value;
      }
      elsif ( _is_hash( $current->{$final_key} ) && _is_hash($value) ) {
        %{ $current->{$final_key} } = ( %{ $current->{$final_key} }, %{$value} );
      }
      elsif ( _is_hash( $current->{$final_key} ) ) {
        croak sprintf q{Error: Attempting to merge a non-hash into a hash at key '%s'.}, $final_key;
      }
      elsif ( exists $current->{$final_key} ) {
        $current->{$final_key} = [ $current->{$final_key}, $value ];
      }
      else {
        $current->{$final_key} = [$value];
      }
    }
    elsif ( $action eq q{-} ) {
      if ( _is_array( $current->{$final_key} ) ) {
        @{ $current->{$final_key} } = grep { $_ ne $value } @{ $current->{$final_key} };
      }
      elsif ( _is_hash( $current->{$final_key} ) ) {
        delete $current->{$final_key}{$value};
      }
      else {
        delete $current->{$final_key};
      }
    }
    else {
      croak sprintf q{Error: Attempting to replace a hash reference at key '%s' with a scalar value.},
        $final_key
        if _is_hash( $current->{$final_key} ) && !_is_hash($value);

      $current->{$final_key} = $value;
    }
  }

  return $self;
}

########################################################################
sub get {
########################################################################
  my ( $self, @key_paths ) = @_;
  my @results;

  for my $key_path (@key_paths) {
    my @keys    = split /[.]/, $key_path;
    my $current = $self->{data};

    for my $key (@keys) {
      if ( _is_hash($current) && exists $current->{$key} ) {
        $current = $current->{$key};
      }
      else {
        $current = undef;
        last;
      }
    }

    push @results, $current;
  }

  return wantarray ? @results : $results[0];  # Ensure it works in scalar and list context
}

########################################################################
sub as_string {
########################################################################
  my ($self) = @_;

  return JSON->new->pretty->encode( $self->{data} ) if $FORMAT eq 'JSON' && $JSON_PRETTY;
  return JSON->new->encode( $self->{data} )         if $FORMAT eq 'JSON';
  return YAML::Dump( $self->{data} )                if $FORMAT eq 'YAML';
  return Dumper( $self->{data} )                    if $FORMAT eq 'Dumper';
  return nfreeze( $self->{data} )                   if $FORMAT eq 'Storable';

  croak "Unsupported format: $FORMAT";
}

########################################################################
sub delete {
########################################################################
  my ( $self, @key_paths ) = @_;

  for my $key_path (@key_paths) {
    my @keys    = split /[.]/, $key_path;
    my $current = $self->{data};
    my @parents;  # Track parent references

    for my $key ( @keys[ 0 .. $#keys - 1 ] ) {
      last if !_is_hash($current) || !exists $current->{$key};

      push @parents, [ $current, $key ];  # Store parent reference
      $current = $current->{$key};
    }

    my $final_key = $keys[-1];
    delete $current->{$final_key} if exists $current->{$final_key};

    # Cleanup empty parent hashes
    while (@parents) {
      my ( $parent, $key ) = @{ pop @parents };

      if ( _is_hash( $parent->{$key} ) && !%{ $parent->{$key} } ) {
        delete $parent->{$key};
      }
    }
  }

  return $self;
}

########################################################################
sub exists_key {
########################################################################
  my ( $self, @key_paths ) = @_;
  my @results;

  for my $key_path (@key_paths) {
    my @keys    = split /[.]/, $key_path;
    my $current = $self->{data};
    my $exists  = 1;

    for my $key (@keys) {
      if ( _is_hash($current) && exists $current->{$key} ) {
        $current = $current->{$key};
      }
      else {
        $exists = 0;
        last;
      }
    }

    push @results, $exists;
  }

  return wantarray ? @results : $results[0];  # Ensures proper scalar context behavior
}

1;

__END__

=pod

=head1 NAME

Data::NestedKey - Object-oriented handling of deeply nested hash structures.

=head1 SYNOPSIS

  use Data::NestedKey;

  my $nk = Data::NestedKey->new(
      'foo.bar.baz' => 42,
      'foo.bar.qux' => 'hello'
  );

  $nk->set('foo.bar.baz' => 99, 'foo.xyz' => [1, 2, 3]);
  my $baz = $nk->get('foo.bar.baz');
  $nk->delete('foo.bar.baz');
  print $nk->as_string();

=head1 DESCRIPTION

Data::NestedKey provides an object-oriented approach to managing deeply nested 
hash structures using dot-separated keys. This allows structured data to be 
manipulated in a clean and intuitive way without requiring manual traversal 
of nested hashes.

While traditional hash manipulation requires explicitly iterating through nested 
structures, this module allows setting and retrieving values using simple text 
strings. The ability to specify a path using a single, dot-separated key improves 
readability, reduces boilerplate, and enhances efficiency when working with complex 
data structures.

A key motivation for this module is configuration file manipulation. Many applications 
use structured configuration files (e.g., JSON, YAML) where default settings exist, 
but some values require customization. This module enables modifying specific 
configuration elements using intuitive dot-separated keys, making updates more 
straightforward.

For example, given a JSON configuration file, a utility could allow:

   init-config foo.json session_files.dir /some/path

Where the command takes the configuration file name followed by key-value pairs 
representing the specific elements to update. This approach provides a simple 
and effective way to adjust settings without needing to manually traverse the 
configuration structure.

The class also supports serialization in multiple formats, controlled by 
package variables:

=over 4

=item * C<$Data::NestedKey::JSON_PRETTY> (default: 1)

Controls whether JSON output is formatted prettily or in a compact form.

=item * C<$Data::NestedKey::FORMAT> (default: 'JSON')

Specifies the serialization format. Supported formats:

    - JSON (default)
    - YAML
    - Data::Dumper
    - Storable

=back

=head1 METHODS AND SUBROUTINES

=head2 new([$hash_ref], @kv_list)

Creates a new Data::NestedKey object. If no arguments are provided, initializes 
with an empty structure. Optionally, an initial hash reference can be supplied. 
Key-value pairs may also be provided for immediate population.

Returns a C<Data::NestedKey> object.

=head2 set(@kv_list)

Inserts, updates, appends, or removes values in the nested structure using dot-separated keys.

=over 4

=item * If a key already exists and holds a scalar, assigning a new value will **replace** it.

=item * If the `+` prefix is used (e.g., `+key`), the value will be **appended**:

    $nk->set('foo.bar' => 1);
    $nk->set('+foo.bar' => 2);
    $nk->set('+foo.bar' => 3);
    # foo.bar now contains [1, 2, 3]

=item * If the `+` prefix is used with a hash, it merges keys instead of replacing:

    $nk->set('config' => { key1 => 'val1' });
    $nk->set('+config' => { key2 => 'val2' });
    # config now contains { key1 => 'val1', key2 => 'val2' }

=item * If the `-` prefix is used (e.g., `-key`), the value is **removed**:

    $nk->set('-foo.bar' => 2);
    # If foo.bar is an array, it removes element '2'
    # If foo.bar is a hash, it removes key '2'
    # Otherwise, it deletes foo.bar entirely

=back

Returns the object itself.

=head2 get(@key_paths)

Retrieves values from the nested structure based on dot-separated keys.

Returns a list of values corresponding to the requested keys.

=head2 delete(@key_paths)

Removes the specified keys from the nested structure.

Returns the object itself.

=head2 exists_key(@key_paths)

Checks whether the given keys exist in the nested structure.

Returns a list of boolean values (1 for exists, 0 for does not exist).

=head2 as_string()

Serializes the nested structure into a string using the specified format.

You can also use the "" to interpolate the object into its serialized
representation. Set the C<$Data::NestedKey::FORAMAT> variable if you
want to change the default format from JSON to another format.

Returns a string representation of the data.

=head2 clear()

Clears all stored data in the object.

Returns the object itself.

=head1 AUTHORS

Rob Lauer <rlauer6@comcast.net>

=head1 SEE ALSO

L<Data::Dumper>, L<JSON>, L<YAML>, L<Storable>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
