package Data::NestedKey;

# This module provides an object-oriented way to manipulate deeply
# nested hash structures using dot-separated keys, with flexible
# serialization options.

use strict;
use warnings;

use Carp;
use Data::Dumper;
use JSON;
use List::Util qw(pairs);
use Scalar::Util qw(reftype);
use Storable qw(nfreeze);
use YAML::XS ();

our $VERSION = '1.2.2';

# Package variables for serialization options
our $JSON_PRETTY = 1;  # Controls whether JSON output is pretty or compact
our $FORMAT = 'JSON';  # Default serialization format

use overload '""' => \&as_string;

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $init_data = ref $args[0] ? shift @args : {};
  my @kv_list   = @args;

  # Accept a hash ref OR an array ref as the data root; anything else
  # (a non-ref first arg) is treated as the start of the kv list.
  my $data
    = ( _is_hash($init_data) || _is_array($init_data) ) ? $init_data : {};

  my $self = bless { data => $data }, $class;

  # If the first arg wasn't usable as init data, treat it as a kv element.
  if ( !_is_hash($init_data) && !_is_array($init_data) ) {
    @kv_list = ( $init_data, @kv_list );
  }

  return $self
    if !@kv_list;

  croak 'Must provide key-value pairs'
    if @kv_list % 2 != 0;

  # set() only makes sense against a hash root; reject kv pairs on an array root.
  croak 'Cannot set key-value pairs on an array-rooted structure'
    if _is_array( $self->{data} ) && @kv_list;

  $self->set(@kv_list);

  return $self;
}

########################################################################
sub _is_array { return ref $_[0] && reftype( $_[0] ) eq 'ARRAY'; }
########################################################################

########################################################################
sub _is_hash { return ref $_[0] && reftype( $_[0] ) eq 'HASH'; }
########################################################################

# Parse a dot-separated path into a list of segment hashrefs.
# Each segment has:
#   key   => the hash key name
#   index => array index (integer, possibly negative), or undef if none
#
# Examples:
#   'foo.bar'             -> [{key=>'foo'},{key=>'bar'}]
#   'repositories[0].uri' -> [{key=>'repositories',index=>0},{key=>'uri'}]
#   'items[-1]'           -> [{key=>'items',index=>-1}]

########################################################################
sub _parse_path {
########################################################################
  my ($path) = @_;

  my @segments;

  for my $part ( split /[.]/, $path ) {
    if ( $part =~ /\A (.*?) \[ (-?\d+) \] \z/xsm ) {
      my ( $key, $idx ) = ( $1, $2 + 0 );

      if ( length $key ) {
        push @segments, { key => $key, index => $idx };
      }
      else {
        push @segments, { index => $idx };  # bare subscript: [0], [-1]
      }
    }
    else {
      push @segments, { key => $part, index => undef };
    }
  }

  return @segments;
}

# Walk a parsed path down into $data, stopping one segment before the
# end.  Returns ($node, $final_segment) where $node is the innermost
# container the final segment lives in, or (undef, undef) if any
# intermediate step is missing or of the wrong type.
#
# If $create is true, missing intermediate hash keys are auto-vivified
# (mirrors the old behaviour in set()).  Array slots are never
# auto-vivified here — callers that need that must handle it themselves.

########################################################################
sub _walk {
########################################################################
  my ( $data, $segments, $create ) = @_;

  my $current = $data;

  for my $seg ( @{$segments}[ 0 .. $#{$segments} - 1 ] ) {
    my ( $key, $idx ) = @{$seg}{qw(key index)};

    # Step into the hash key only if this segment has one.
    if ( exists $seg->{key} ) {
      if ( _is_hash($current) ) {
        $current->{$key} //= {} if $create && !exists $current->{$key};

        return ( undef, undef ) if !exists $current->{$key};

        $current = $current->{$key};
      }
      else {
        return ( undef, undef );
      }
    }

    # If this segment carries an array subscript, step into it.
    if ( defined $idx ) {
      return ( undef, undef ) if !_is_array($current);

      $current = $current->[$idx];

      return ( undef, undef ) if !defined $current;
    }
  }

  return ( $current, $segments->[-1] );
}

########################################################################
sub set {
########################################################################
  my ( $self, @kv_list ) = @_;

  croak 'Must provide key-value pairs'
    if @kv_list % 2 != 0;

  for my $p ( pairs @kv_list ) {
    my ( $key_path, $value ) = @{$p};
    my $action = $key_path =~ s/\A([+-])//xsm ? $1 : q{};

    # set() does not support array subscripts in paths; use plain dot-keys only.
    croak "Array subscripts (e.g. key[0]) are not supported in set() paths: '$key_path'"
      if $key_path =~ /\[/;

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
      croak sprintf q{Error: Attempting to replace a hash reference at key '%s' with a scalar value.}, $final_key
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
    my @segments = _parse_path($key_path);
    my $current  = $self->{data};
    my $ok       = 1;

    for my $seg (@segments) {
      my ( $key, $idx ) = @{$seg}{qw(key index)};

      # Step into a hash key only if this segment has one.
      if ( exists $seg->{key} ) {
        if ( _is_hash($current) && exists $current->{$key} ) {
          $current = $current->{$key};
        }
        else {
          $current = undef;
          $ok      = 0;
          last;
        }
      }

      if ( defined $idx ) {
        if ( _is_array($current) ) {
          $current = $current->[$idx];
        }
        else {
          $current = undef;
          $ok      = 0;
          last;
        }
      }
    }

    push @results, $ok ? $current : undef;
  }

  return wantarray ? @results : $results[0];
}

########################################################################
sub as_string {
########################################################################
  my ($self) = @_;

  return JSON->new->pretty->encode( $self->{data} ) if $FORMAT eq 'JSON' && $JSON_PRETTY;
  return JSON->new->encode( $self->{data} )         if $FORMAT eq 'JSON';
  return YAML::XS::Dump( $self->{data} )            if $FORMAT eq 'YML';
  return YAML::XS::Dump( $self->{data} )            if $FORMAT eq 'YAML';
  return Dumper( $self->{data} )                    if $FORMAT eq 'Dumper';
  return nfreeze( $self->{data} )                   if $FORMAT eq 'Storable';

  croak "Unsupported format: $FORMAT";
}

########################################################################
sub delete { ## no critic
########################################################################
  my ( $self, @key_paths ) = @_;

  for my $key_path (@key_paths) {
    my @segments = _parse_path($key_path);
    my @parents;  # Track parent containers for empty-hash cleanup
    my $current = $self->{data};
    my $abort   = 0;

    for my $seg ( @segments[ 0 .. $#segments - 1 ] ) {
      my ( $key, $idx ) = @{$seg}{qw(key index)};

      last if !_is_hash($current) || !exists $current->{$key};

      push @parents, [ $current, $key ];
      $current = $current->{$key};

      if ( defined $idx ) {
        if ( _is_array($current) ) {
          $current = $current->[$idx];

          if ( !defined $current ) {
            $abort = 1;
            last;
          }
          # Array slots are not tracked for empty-cleanup
          @parents = ();
        }
        else {
          $abort = 1;
          last;
        }
      }
    }

    next if $abort;

    my $final = $segments[-1];
    my ( $final_key, $final_idx ) = @{$final}{qw(key index)};

    if ( defined $final_idx ) {
      # Deleting a specific array slot: splice it out
      if ( _is_hash($current)
        && exists $current->{$final_key}
        && _is_array( $current->{$final_key} ) ) {
        splice @{ $current->{$final_key} }, $final_idx, 1;
      }
    }
    else {
      if ( _is_hash($current) && exists $current->{$final_key} ) {
        delete $current->{$final_key};
      }
    }

    # Cleanup empty parent hashes (only meaningful when no array was traversed)
    while (@parents) {
      my ( $parent, $key ) = @{ pop @parents };
      last if !_is_hash( $parent->{$key} ) || %{ $parent->{$key} };
      delete $parent->{$key};
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
    my @segments = _parse_path($key_path);
    my $current  = $self->{data};
    my $exists   = 1;

    for my $seg (@segments) {
      my ( $key, $idx ) = @{$seg}{qw(key index)};

      if ( _is_hash($current) && exists $current->{$key} ) {
        $current = $current->{$key};
      }
      else {
        $exists = 0;
        last;
      }

      if ( defined $idx ) {
        if ( _is_array($current) && defined $current->[$idx] ) {
          $current = $current->[$idx];
        }
        else {
          $exists = 0;
          last;
        }
      }
    }

    push @results, $exists;
  }

  return wantarray ? @results : $results[0];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::NestedKey - Object-oriented handling of deeply nested hash structures.

=head1 SYNOPSIS

  use Data::NestedKey;

  my $nk = Data::NestedKey->new(
      'foo.bar.baz' => 42,
      'foo.bar.qux' => 'hello'
  );

  $nk->set('foo.bar.baz' => 99, 'foo.xyz' => [1, 2, 3]);

  # Plain dot-path access
  my $baz = $nk->get('foo.bar.baz');

  # Array subscript access
  my $nk2 = Data::NestedKey->new($ecr_response);
  my $uri  = $nk2->get('repositories[0].repositoryUri');

  $nk->delete('foo.bar.baz');
  print $nk->as_string();

  # use the CLI version
  cat ecr-response.json | dnk 'repositories[0].repositoryUri'

=head1 DESCRIPTION

C<Data::NestedKey> (and the CLI script C<dnk>) provide a lightweight
way to manipulate deeply nested data structures use dot-separated
keys.

C<Data::NestedKey> provides an object-oriented approach to this
functionality. These tools allow structured data to be manipulated in a
clean and intuitive way without requiring manual traversal of nested
hashes.

These tools can be particularly useful in replacing C<jq> as a
dependency when the full power of C<jq> is not required.

Path strings use dots to separate hash keys. Array elements may be accessed
by appending a zero-based subscript in square brackets to any hash key segment.
Negative indices count from the end of the array (C<-1> is the last element).

  repositories[0].repositoryUri   # first element of the repositories array
  items[-1].name                  # last element of the items array
  a.b[2].c.d[-1]                  # deeply nested mix of hashes and arrays

The root of the structure may itself be an array. A path that begins with a
bare subscript indexes the top-level array directly:

  [0].name        # 'name' field of the first top-level element
  [-1]            # the last top-level element

Array subscript notation is supported in C<get>, C<exists_key>, and C<delete>
(including bare leading subscripts against an array root). It is B<not>
supported in C<set> (see below).

A key motivation for this module is configuration file and API response
manipulation. Many applications use structured data (e.g., JSON, YAML) where
values are nested several levels deep. This module enables reading and modifying
specific elements using intuitive dot-separated keys, making access more
straightforward.

For example, given a JSON configuration file, a utility could allow:

   init-config foo.json session_files.dir /some/path

Where the command takes the configuration file name followed by key-value pairs
representing the specific elements to update.

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

=head2 new([$data_ref], @kv_list)

Creates a new Data::NestedKey object. If no arguments are provided, initializes
with an empty structure. Optionally, an initial data reference can be supplied
as the root: either a B<hash reference> or an B<array reference>. Key-value
pairs may also be provided for immediate population, but only when the root is
a hash (or defaulted) — supplying key-value pairs together with an array-ref
root throws an exception, since C<set> operates on dot-separated hash keys.

Returns a C<Data::NestedKey> object.

=head2 set(@kv_list)

Inserts, updates, appends, or removes values in the nested structure using
dot-separated keys. Array subscript notation (e.g. C<key[0]>) is B<not>
supported in C<set> paths — nor can values be set against an array-rooted
structure — and an exception is thrown in either case. To modify array
contents, retrieve the parent with C<get>, alter the Perl structure directly,
and construct a new object if needed.

=over 4

=item * If a key already exists and holds a scalar, assigning a new value will B<replace> it.

=item * If the C<+> prefix is used (e.g., C<+key>), the value will be B<appended>:

    $nk->set('foo.bar' => 1);
    $nk->set('+foo.bar' => 2);
    $nk->set('+foo.bar' => 3);
    # foo.bar now contains [1, 2, 3]

=item * If the C<+> prefix is used with a hash, it merges keys instead of replacing:

    $nk->set('config' => { key1 => 'val1' });
    $nk->set('+config' => { key2 => 'val2' });
    # config now contains { key1 => 'val1', key2 => 'val2' }

=item * If the C<-> prefix is used (e.g., C<-key>), the value is B<removed>:

    $nk->set('-foo.bar' => 2);
    # If foo.bar is an array, it removes element '2'
    # If foo.bar is a hash, it removes key '2'
    # Otherwise, it deletes foo.bar entirely

=back

Returns the object itself.

=head2 get(@key_paths)

Retrieves values from the nested structure based on dot-separated key paths.
Array elements may be accessed with C<[n]> subscripts (zero-based; negative
indices count from the end):

  my $uri  = $nk->get('repositories[0].repositoryUri');
  my $last = $nk->get('items[-1].name');

The root may be an array, in which case a leading subscript indexes it
directly:

  my $first = $nk->get('[0]');
  my $name  = $nk->get('[0].name');

Returns C<undef> for any path that does not exist or whose subscript is out
of range.  In list context returns all requested values; in scalar context
returns the first.

=head2 delete(@key_paths)

Removes the specified keys from the nested structure. If the final segment
carries an array subscript, the element is removed with C<splice> (the array
shrinks; no undef hole is left). Empty parent hashes are pruned automatically
when no array is traversed on the way down.

Returns the object itself.

=head2 exists_key(@key_paths)

Checks whether the given keys exist in the nested structure. Array subscripts
are honoured: a subscript pointing past the end of an array, or to an undef
slot, is treated as non-existent.

Returns a list of boolean values (1 for exists, 0 for does not exist).

=head2 as_string()

Serializes the nested structure into a string using the specified format.

The C<""> operator is overloaded to call this method, so the object may be
interpolated directly into strings.  Set C<$Data::NestedKey::FORMAT> to change
the default format from JSON.

Returns a string representation of the data.

=head1 AUTHOR

Rob Lauer <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO

L<Data::Dumper>, L<JSON>, L<YAML::XS>, L<Storable>

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut
