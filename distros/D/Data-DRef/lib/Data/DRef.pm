### Data::DRef - Delimited-key access to complex data structures

### Copyright 1996, 1997, 1998, 1999 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License. 

### Change History
  # 1999-02-06 Added to CPAN module list. Repackaged for distribution.
  # 1999-01-31 Collapsed Data::Collection into Data::DRef.
  # 1999-01-31 Removed Data::Collection's dependancy on Data::Sorting.
  # 1999-01-22 Revision of documentation, and improved Exporter tagging.
  # 1998-12-01 Added get_value_for_optional_dref; minor doc revisions.
  # 1998-10-15 Added explicit undef return value from get_value_for_key.
  # 1998-10-14 Added doc caveat about possible use of UNIVERSAL methods.
  # 1998-10-07 Reworked, conventionalized documentation and Exporter behaviour.
  # 1998-10-06 Refactored value_for_keys algorithm; clarified dref syntax.
  # 1998-07-16 Preliminary support for DRef pragmas: ignore (!reverse). -Simon
  # 1998-05-21 Added undef behavior in matching_keys and matching_values.
  # 1998-05-07 Replaced map with foreach in a few places.
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-04-10 Added hash_by_array_key.
  # 1998-04-09 Fixed single-item problem with scalarkeysof algorithm. -Simon
  # 1998-03-12 Patched dref manipulation functions to escape separator.
  # 1998-02-24 Changed valuesof to return value of non-ref arguments. -Piglet
  # 1998-01-30 Added array_by_hash_key($) and intersperse($@) -Simon
  # 1997-12-08 Removed package Data::Types, replaced with UNIVERSAL isa.
  # 1997-12-07 Exported uniqueindexby.  -Piglet
  # 1997-11-24 Finished orderedindexby.
  # 1997-11-19 Renamed removekey function to shiftdref at Jeremy's suggestion.
  # 1997-11-14 Added resolveparens behaviour to standard syntax.
  # 1997-11-14 Added getDRef, setDRef functions as can() wrappers for get, set
  # 1997-11-13 Added orderedindexby, but it still needs a bit of work.
  # 1997-10-29 Add'l modifications; replaced recursion with iteration in get()
  # 1997-10-25 Revisions; separator changed from colon to period.
  # 1997-10-03 Refactored get and set operations
  # 1997-09-05 Package split from the original dataops.pm into Data::*.
  # 1997-04-18 Cleaned up documentation a smidge.
  # 1997-04-08 Added getbysubkeys, now called matching_values
  # 1997-01-29 Altered set to create hashes even for numerics
  # 1997-01-28 Possible fix to recurring "keysof operates on containers" error.
  # 1997-01-26 Catch bad argument types for sortby, indexby.
  # 1997-01-21 Failure for keysof, valuesof now returns () rather than undef.
  # 1997-01-21 Added scalarsof.
  # 1997-01-11 Cloned and cleaned for IWAE; removed asdf code to dictionary.pm.
  # 1996-11-18 Moved v2 code into production, additional cleanup. -Simon
  # 1996-11-13 Version 2.00, major overhaul. 
  # 1996-10-29 Fixed set to handle '0' items. -Piglet
  # 1996-09-09 Various changes, esp. fixing get to handle '0' items. -Simon
  # 1996-07-24 Wrote copy, getString, added 'append' to set.
  # 1996-07-18 Wrote setData, fixed headers.  -Piglet
  # 1996-07-18 Additional Exporter fudging.
  # 1996-07-17 Globalized theData. -Simon
  # 1996-07-13 Simplified getData into get; wrote set. -Piglet
  # 1996-06-25 Various tweaks.
  # 1996-06-24 First version of dataops.pm created. -Simon

package Data::DRef;

require 5;
use strict;
use Carp;
use Exporter;

use String::Escape qw( printable unprintable );

use vars qw( $VERSION @ISA %EXPORT_TAGS );
$VERSION = 1999.02_06;

push @ISA, qw( Exporter );
%EXPORT_TAGS = (
  key_access => [ qw(
    get_keys get_values get_value_for_key set_value_for_key 
    get_or_create_value_for_key get_reference_for_key 
    get_value_for_keys set_value_for_keys
  ) ], 
  dref_syntax => [ qw(
    $Separator $DRefPrefix dref_from_keys keys_from_dref 
    join_drefs unshift_dref_key shift_dref_key resolve_pragmas
  ) ], 
  dref_access => [ qw(
    get_key_drefs get_value_for_dref set_value_for_dref 
  ) ], 
  root_dref => [ qw(
    $Root get_value_for_root_dref set_value_for_root_dref
  ) ], 
  'select' => [ qw( 
    matching_keys matching_values 
  ) ], 
  'index' => [ qw(
    index_by_drefs unique_index_by_drefs ordered_index_by_drefs
  ) ], 
  'leaf' => [ qw( 
    leaf_drefs leaf_values leaf_drefs_and_values 
  ) ], 
  compat => [ qw(
    getData setData getDRef setDRef joindref shiftdref $Root get set 
    $Separator splitdref keysof valuesof scalarkeysof scalarkeysandvalues 
    matching_values matching_keys indexby uniqueindexby orderedindexby
  ) ], 
);
Exporter::export_ok_tags( keys %EXPORT_TAGS );

### Value-For-Key Interface

# @keys = get_keys($target)
sub get_keys {
  my $target = shift;
  
  if ( UNIVERSAL::can($target, 'm_get_keys') ) {
    return $target->m_get_keys(@_);
  } elsif ( UNIVERSAL::isa($target, 'HASH') ) {
    return keys %$target;
  } elsif ( UNIVERSAL::isa($target, 'ARRAY') ) {
    return ( 0 .. $#$target );
  } else {
    return ();
  }
}

# @values = get_values($target)
  # Returns a list of scalar values in a referenced hash or list
sub get_values {
  my $target = shift;
  
  if ( UNIVERSAL::can($target, 'm_get_values') ) {
    return $target->m_get_values(@_);
  } elsif ( UNIVERSAL::isa($target, 'HASH') ) {
    return values %$target;
  } elsif ( UNIVERSAL::isa($target, 'ARRAY') ) {
    return @$target; 
  } elsif ( ! ref $target ) {
    return $target;
  } else {
    return ();
  }
}

# $value = get_value_for_key($target, $key);
sub get_value_for_key ($$) {
  my $target = shift;
  croak "get called without target \n" unless (defined $target);
  
  my $key = shift;
  
  if ( UNIVERSAL::can($target, 'm_get_value_for_key') ) {
    return $target->m_get_value_for_key($key);
  } elsif ( UNIVERSAL::isa($target, 'HASH') ) {
    return $target->{$key} if (exists $target->{$key});
  } elsif ( UNIVERSAL::isa($target, 'ARRAY') ) {
    carp "Use of non-numeric key '$key'" unless ( $key eq '0' or $key > 0 );
    return $target->[$key] if ($key >= 0 and $key < scalar @$target);
  } else {
    carp "'$target' can't get_value_for_key '$key'\n";
  }
  return undef;
}

# set_value_for_key($target, $key, $value);
sub set_value_for_key ($$$) {
  my $target = shift;
  croak "set_value_for_key called without target \n" unless (defined $target);
  
  if ( UNIVERSAL::can($target, 'm_set_value_for_key') ) {
    return $target->m_set_value_for_key(@_);
  } elsif ( UNIVERSAL::isa($target, 'HASH') ) {
    $target->{ $_[0] } = $_[1];
  } elsif ( UNIVERSAL::isa($target, 'ARRAY') ) {
    $target->[ $_[0] ] = $_[1];
  } else {
    # We do not natively support set() on anything else.
    carp "'$target' can't set_value_for_key '$_[0]'\n";
  }
}

# $value = get_or_create_value_for_key($target, $key);
sub get_or_create_value_for_key {
  my $target = shift;  
  my $key = shift;
  
  return $target->m_get_or_create_value_for_key($key)
	if ( UNIVERSAL::can($target, 'm_get_or_create_value_for_key') );
  
  my $value = get_value_for_key($target, $key);
  
  unless (defined $value) {
    $value = {};
    set_value_for_key($target, $key, $value);
  }
  
  return $value;
}

# $value_reference = get_reference_for_key($target, $key);
sub get_reference_for_key ($$) {
  my $target = shift;
  croak "get_reference_for_key called w/o target\n" unless (defined $target);
  
  my $key = shift;
  
  if ( UNIVERSAL::can($target, 'm_get_reference_for_key') ) {
    return $target->m_get_reference_for_key($key);
  } elsif ( UNIVERSAL::isa($target, 'HASH') ) {
    return \${$target}{$key};
  } elsif ( UNIVERSAL::isa($target, 'ARRAY') ) {
    return \${$target}[$key];
  } else {
    carp "'$target' can't get_reference_for_key '$_[0]'\n";
  }
}

### Multiple-Key Chaining
  # 
  # These functions allow access through a series of keys. Generally, the list 
  # of keys is interpreted each starting from the result of the previous one. 

# $value = get_value_for_keys($target, @keys);
sub get_value_for_keys ($@) {
  my $target = shift;
  croak "get_value_for_keys called without target \n" unless (defined $target);
  croak "get_value_for_keys called without keys \n" unless (scalar @_);
  
  while ( scalar @_ ) {
    # If we've got keys remaining, use the appropriate get method...
    return $target->m_get_value_for_keys(@_) 
	if UNIVERSAL::can($target, 'm_get_value_for_keys');
    
    my $key = shift @_;
    my $result = get_value_for_key($target, $key);
    
    # If there aren't any more keys, we're done!
    return $result unless (scalar @_);
    
    # We can't keep going without a ref value, despite the remaining keys
    return undef unless (ref $result);
    
    # ... or select the target and iterate through another key
    $target = $result;
  }
}

# set_value_for_keys($target, $value, @keys);
sub set_value_for_keys {
  my $target = shift;
  my $value = shift;
  
  croak "set_value_for_keys called without target \n" unless (defined $target);
  croak "set_value_for_keys called without keys \n" unless (scalar @_);
  
  while ( scalar @_ ) {
    return $target->m_set_value_for_keys($value, @_) 
	  if UNIVERSAL::can($target, 'm_set_value_for_keys');
    
    my $key = shift @_;
    
    # Last key -- we're at the end of the line
    return set_value_for_key($target, $key, $value) unless (scalar @_);
    
    # Get the value for this key, or create an empty hash ref to build into.
    my $result = get_or_create_value_for_key($target, $key);
        
    # We've got keys remaining, but we can't keep going
    return undef unless (ref $result);
    
    $target = $result;
  }
}

# $value = get_or_create_value_for_keys($target, @keys);
sub get_or_create_value_for_keys {
  my $target = shift;
  my $value = shift;
  
  croak "set_value_for_keys called without target \n" unless (defined $target);
  croak "set_value_for_keys called without keys \n" unless (scalar @_);
  
  while ( scalar @_ ) {
    return $target->m_get_or_create_value_for_keys($value, @_) 
	  if UNIVERSAL::can($target, 'm_get_or_create_value_for_keys');
    
    my $key = shift @_;
    my $result = get_or_create_value_for_key($target, $key);
    
    # If there aren't any more keys, we're done!
    return $result unless (scalar @_);
    
    # We can't keep going without a ref value, despite the remaining keys
    return undef unless (ref $result);
    
    # ... or select the target and iterate through another key
    $target = $result;
  }
}

# $val_ref = get_reference_for_keys($target, @keys);
sub get_reference_for_keys {
  my $target = shift;
  
  croak "get_reference_for_keys called w/o target\n" unless (defined $target);
  croak "get_reference_for_keys called w/o keys \n" unless (scalar @_);
  
  while ( scalar @_ ) {
    return $target->m_get_reference_for_keys(@_) 
	  if UNIVERSAL::can($target, 'm_get_reference_for_keys');
    
    my $key = shift @_;
    
    # Last key -- we're at the end of the line
    return get_reference_for_key($target, $key) unless (scalar @_);
    
    # Get the value for this key, or create an empty hash ref to build into.
    my $result = get_or_create_value_for_key($target, $key);
    
    # We've got keys remaining, but we can't keep going
    return undef unless (ref $result);
    
    $target = $result;
  }
}

### DRef Syntax
  # 
  # DRef strings are dot-separated 

# $Separator - Multiple-key delimiter character
use vars qw( $Separator $DRefPrefix );
$Separator = '.';
$DRefPrefix = '#';

# @drefs = get_key_drefs($target);
sub get_key_drefs {
  map { printable($_) } get_keys( @_ );
}

# $dref = dref_from_keys( @keys );
  # Return a dref composed of a list of $Separator-protected keys 
sub dref_from_keys (@) {
  join $Separator, map { printable($_) } @_;
}

# @keys = keys_from_dref( $dref );
  # Return a series of key strings extracted from a dref
sub keys_from_dref ($) {
  my $dref = shift;
  my @keys;
  while ( defined $dref and length $dref ) {
    $dref =~ s/\A((?:[^\\\Q$Separator\E]+|\\.)*)(?:\Q$Separator\E|\Z)//m;
    push(@keys, unprintable($1));
  }
  return @keys;
}

# $dref = join_drefs( @drefs );
sub join_drefs (@) { 
  join($Separator, @_); 
}

# unshift_dref_key( $dref, $key );
  # Prepends key to dref -- modifies value of first argument
sub unshift_dref_key {
  $_[0] = join($Separator, unprintable($_[1]), $_[0]);
}

# $key = shift_dref_key( $dref );
  # Removes first key from dref -- modifies value of its argument
sub shift_dref_key {
  $_[0] =~ s/\A((?:[^\\\Q$Separator\E]+|\\.)*)(?:\Q$Separator\E|\Z)//m;
  return unprintable($1);
}

# $dref = resolve_pragmas( $dref_with_embedded_parens );
# ($dref, %options) = resolve_pragmas( $dref_with_embedded_parens );
sub resolve_pragmas ($) {
  my $path = shift;
  my $options = {};
  
  do {} while ( 
    $path =~ s/(\A|[^\\]|[^\\](?:\\{2})*)\(([\#\!])([^\(\)]+)\)
		    /$1._expand_pragma($2, $3, $options)/ex 
  );
  
  return wantarray ? ($path, %$options) : $path;
}

sub _expand_pragma {
  my ($type, $value, $options) = @_;
  if ( $type eq $DRefPrefix ) {
    return get_value_for_root_dref($value);
  } elsif ( $type eq '!' ) {
    $options->{ $value } = 1;
  } else {
    carp "use of unsupported DRef pragma '$type$value'";
  }
  return '';
}

### DRef Access

# $value = get_value_for_dref($target, $dref);
sub get_value_for_dref {
  get_value_for_keys $_[0], keys_from_dref( (resolve_pragmas($_[1]))[0] );
}

# set_value_for_dref($target, $dref, $value);
sub set_value_for_dref {
  set_value_for_keys $_[0], $_[2], keys_from_dref((resolve_pragmas($_[1]))[0]);
}

### Shared Data Graph Entry

# $Root - Data graph entry point
use vars qw( $Root );
$Root = {};

# $value = get_value_for_root_dref($dref);
sub get_value_for_root_dref ($)  { 
  get_value_for_dref($Root, @_) 
}

# $value = set_value_for_root_dref($dref, $value);
sub set_value_for_root_dref ($$) { 
  set_value_for_dref($Root, @_) 
}

# $value = get_value_for_optional_dref($literal_or_dref_with_leading_hashmark);
sub get_value_for_optional_dref ($)  { 
  $_[0] =~ /^\Q$DRefPrefix\E(.*)/o ? get_value_for_root_dref($1) : $_[0]
}

### Select by DRefs

# $key or @keys = matching_keys($target, %dref_value_criteria_pairs);
sub matching_keys {
  my($target, %kvp_criteria) = @_;
  return unless ($target and scalar %kvp_criteria);
  my ($key, $dref, @keys);
  ITEM: foreach $key (get_keys $target) {
    my $item = get_value_for_key($target,$key);
    foreach $dref (keys %kvp_criteria) {
      next ITEM unless $kvp_criteria{$dref} eq ( 
        defined $dref && length $dref ? get_value_for_dref($item,$dref) : $item 
      );
    }
    return $key unless (wantarray);
    push @keys, $key;
  }
  return @keys;
}

# $item or @items = matching_values($target, %dref_value_criteria_pairs);
sub matching_values {
  my($target, %kvp_criteria) = @_;
  my($item, $dref, @items);
  ITEM: foreach $item ( get_values($target) ) {
    foreach $dref (keys %kvp_criteria) {
      next ITEM unless $kvp_criteria{$dref} eq ( 
        defined $dref && length $dref ? get_value_for_dref($item,$dref) : $item 
      );
    }
    return $item unless (wantarray);
    push @items, $item;
  }
  return @items;
}

### Index by DRefs 

# $index = index_by_drefs($target, @drefs)
sub index_by_drefs {
  my($target, @drefs) = @_;
  my $index = {};
  
  my $item;
  foreach $item ( get_values($target) ) {
    my @keys = map { get_value_for_dref($item, $_) } @drefs;
    my $grouping = get_reference_for_keys($index, @keys);
    push @$$grouping, $item;
  }
  
  return $index;
}

# $index = unique_index_by_drefs($target, @drefs)
sub unique_index_by_drefs {
  my($target, @drefs) = @_;
  my $index = {};
  
  my $item;
  foreach $item (get_values ($target)) {
    my @keys = map { get_value_for_dref($item, $_) } @drefs;
    set_value_for_keys($index, $item, @keys);
  }
  
  return $index;
}

# $entry_ary = ordered_index_by_drefs( $target, $index_dref );
sub ordered_index_by_drefs {
  my($target, $grouper) = @_;
  my $index = {};
  my $order = [];
  
  my $item;
  foreach $item ( get_values($target) ) {
    my $value = get_value_for_dref($item, $grouper);
    $value = '' unless (defined $value);
    push @$order, ( 
      $index->{$value} = { 'value' => $value, 'items' => [] } 
    ) unless ( exists($index->{ $value }) );
    push @{ $index->{ $value }{'items'} }, $item;
  }
  return $order;
}

### DRefs to Leaf nodes

# @drefs = leaf_drefs($target);
  # Returns a list of drefs for non-ref leaves in a referenced structure.
  # Keep track of items we've visited previously to protect against loops.
sub leaf_drefs ($) {
  my $target = shift;
  my @drefs = get_key_drefs( $target );
  my %visited;
  my $i;
  for ( $i = 0; $i <= $#drefs; $i++ ) {
    my $dref = $drefs[$i];
    my $value = get_value_for_dref($target, $dref);
    next if ( ! ref $value or $visited{$value}++ );
    my @subkeys = get_key_drefs( $value );
    if ( scalar @subkeys ) {
      splice @drefs, $i, 1, map { join_drefs($dref, $_) } @subkeys;
      $i--;
    }
  }
  return @drefs;
}

# @values = leaf_values( $target )
sub leaf_values ($) {
  my $target = shift;
  map { get_value_for_dref($target, $_) } leaf_drefs( $target );
}

# %dref_value_pairs = leaf_drefs_and_values( $target )
sub leaf_drefs_and_values ($) {
  my $target = shift;
  map { $_, get_value_for_dref($target, $_) } leaf_drefs( $target );
}

### Compatiblity 

*get = *get_value_for_dref;
*set = *set_value_for_dref;
*getDRef = *get_value_for_dref;
*setDRef = *set_value_for_dref;
*getData = *get_value_for_root_dref;
*setData = *set_value_for_root_dref;
*splitdref = *keys_from_dref;
*joindref = *dref_from_keys;
*shiftdref = *shift_dref_key;
*keysof = *get_keys;
*valuesof = *get_values;
*indexby = *index_by_drefs;
*uniqueindexby = *unique_index_by_drefs;
*orderedindexby = *ordered_index_by_drefs;
*scalarkeysof = *leaf_drefs;
*scalarkeysandvalues = *leaf_drefs_and_values;

### Data::DRef::MethodBased

package Data::DRef::MethodBased;

### Minimal DRef Interface for Object Methods

# @keys = $target->m_get_keys()
sub m_get_keys {
  return ();
}

# @values = $target->m_get_values()
sub m_get_values {
  my $target = shift;
  map { $target->m_get_value_for_key($_) } $target->m_get_keys;
}

# $value = $target->m_get_value_for_key($key);
sub m_get_value_for_key {
  my ($target, $key) = @_;
  return $target->$key() if ( $target->can($key) );
  die "$target is unable to get value for key '$key'\n";
}

# $target->m_set_value_for_key($key, $value);
sub m_set_value_for_key {
  my ($target, $key, $value) = @_;
  return $target->$key($value) if ( $target->can($key) );
  die "$target is unable to set value for key '$key'\n";
}

# No default implementation provided for these other supported methods...
  # $value_reference = $target->m_get_reference_for_key($key);
  # $value = $target->m_get_or_create_value_for_key($key);
  # $value = $target->m_get_value_for_keys(@keys);
  # $target->m_set_value_for_keys($value, @keys);
  # $val_ref = $target->m_get_reference_for_keys(@keys);
  # $target->m_set_value_for_keys($value, @keys);

1;

__END__

=head1 NAME

Data::DRef - Delimited-key access to complex data structures


=head1 SYNOPSIS

  use Data::DRef qw( :dref_access );
  my $hash = { 'items' => [ 'first' ] };
  print get_value_for_dref($hash, 'items.0');
  set_value_for_dref( $hash, 'items.1', 'second' );
  
  set_value_for_root_dref( 'myhash', $hash );    
  print get_value_for_root_dref('myhash.items.0');

  use Data::DRef qw( :select );
  matching_keys($target, %filter_criteria) : $key or @keys
  matching_values($target, %filter_criteria) : $item or @items

  use Data::DRef qw( :index );
  index_by_drefs($target, @drefs) : $index
  unique_index_by_drefs($target, @drefs) : $index
  ordered_index_by_drefs( $target, $index_dref ) : $entry_ary
  
  use Data::DRef qw( :leaf );
  leaf_drefs($target) : @drefs
  leaf_values( $target ) : @values
  leaf_drefs_and_values( $target ) : %dref_value_pairs


=head1 DESCRIPTION

Data::DRef provides a streamlined interface for accessing values within
nested Perl data structures. These structures are generally networks of
hashes and arrays, some of which may be blessed into various classes,
containing a mix of simple scalar values and references to other items
in the structure.

The Data::DRef functions allow you to use delimited key strings to set and
retrieve values at desired nodes within these structures. These functions
are slower than direct variable access, but provide additional flexibility
for high-level scripting and other late-binding behaviour. For example,
a web-based application could use DRefs to simplify customization,
allowing the user to refer to arguments processed by CGI.pm in fairly
readable way, such as C<query.param.I<foo>>.

A suite of utility functions, previous maintained in a separate
Data::Collection module, performs a variety of operations across nested
data structures. Because the Data::DRef abstraction layer is used, these
functions should work equally well with arrays, hashes, or objects that
provide their own key-value interface.


=head1 REFERENCE

=head2 Value-For-Key Interface

The first set of functions define our core key-value interface, and
provide its implementation for references to Perl arrays and hashes. For
example, direct access to array and hash keys usually looks like this:

    print $employee->[3];
    $person->{'name'} = 'Joe';

Using these functions, you could replace the above statements with:

    print get_value_for_key( $employee, 3 );
    set_value_for_key( $person, 'name', 'Joe' );

Each of these functions checks for object methods as described below.

=over 4

=item get_keys($target) : @keys

Returns a list of keys for which this item would be able to provide a
value. For hash refs, returns the hash keys; for array refs, returns a
list of numbers from 0 to $#; otherwise returns nothing.

=item get_values($target) : @values

Returns a list of values for this item. For hash refs, returns the hash
values; for array refs, returns the array contents; otherwise returns
nothing.

=item get_value_for_key($target, $key) : $value

Returns the value associated with this key. For hash refs, returns the
value at this key, if present; for array refs, returns the value at this
index, or complains if it's not numeric.

=item set_value_for_key($target, $key, $value)

Sets the value associated with this key. For hash refs, adds or overwrites
the entry for this key; for array refs, sets the value at this index,
or complains if it's not numeric.

=item get_or_create_value_for_key($target, $key) : $value

Gets value associated with this key using get_value_for_key, or if that
value is undefined, sets the value to refer to a new anonymous hash
using set_value_for_key and returns that reference.

=item get_reference_for_key($target, $key) : $value_reference

Returns a reference to the scalar which is used to hold the value
associated with this key.

=back

=head2 Multiple-Key Chaining

Frequently we wish to access values at some remove within a structure
by chaining through a list of references. Programmatic access to these
values within Perl usually looks something like this:

    print $report->{'employees'}[3]{'id'};
    $report->{'employees'}[3]{'name'} = 'Joe';

Using these functions, you could replace the above statements with:

    print get_value_for_keys( $report, 'employees', 3, 'id' );
    set_value_for_keys( $report, 'Joe', 'employees', 3, 'name' );

These functions also support the "m_*" method delegation described above.

=over 4

=item get_value_for_keys($target, @keys) : $value

Starting at the target, look up each of the provided keys sequentially
from the results of the previous one, returning the final value. Return
value is undefined if at any time we find a key for which no value
is present.

=item set_value_for_keys($target, $value, @keys)

Starting at the target, look up each of the provided keys sequentially
from the results of the previous one; when we reach the final key, use
set_value_for_key to make the assignment. If an intermediate value is
undefined, replaces it with an empty hash to hold the next key-value pair.

=item get_or_create_value_for_keys($target, @keys) : $value

As above.

=item get_reference_for_keys($target, @keys) : $val_ref

As above.

=back

=head2 Object Overrides

Each of the value-for-key and multiple-key functions first check for
methods with similar names preceeded by "m_" and, if present, uses
that implementation. For example, callers can consistently request
C<get_value_for_key($foo, $key)>, but in cases where C<$foo> supports a
method named C<m_get_value_for_key>, its results will be returned instead.

Classes that wish to provide alternate DRef-like behavior or generate
values on demand should implement these methods in their packages.
A Data::DRef::MethodBased class is provided for use by objects which use
methods to get and set attributes. By making your package a subclass of
MethodBased you'll inherit m_get_value_for_key and m_set_value_for_key
methods which treat the key as a method name to invoke.


=head2 DRef Syntax

In order to simplify expression of the lists of keys used above,
we define a string format in which they may be represented. A DRef
string is composed of a series of simple scalar keys, each escaped
with String::Escape's printable() function, joined with the $Separator
character, 'C<.>'.

=over 4

=item $Separator

The multiple-key delimiter character, by default C<.>, the period
character.

=item get_key_drefs($target) : @drefs

Uses get_keys to determine the available keys for this target, and then
returns an appropriately-escaped version of each of them.

=item dref_from_keys( @keys ) : $dref

Escapes and joins the provided keys to create a dref string.

=item keys_from_dref( $dref ) : @keys

Splits and unescapes a dref string to its consituent keys.

=item join_drefs( @drefs ) : $dref

Joins already-escaped dref strings into a single dref.

=item unshift_dref_key( $dref, $key )

Modify the provided dref string by escaping and prepending the provided
key.  Note that the original $dref variable is altered.

=item shift_dref_key( $dref ) : $key

Modify the provided dref string by removing and unescaping the first key.
Note that the original $dref variable is altered, and set to '' when
the last key is removed.

=back

=head2 DRef Pragmas

Several types of parenthesized expressions are supported as extension
mechanisms for dref strings. Nested parentheses are supported, with the
innermost parentheses resolved first.

Continuing the above example, one could write:

    set_value_for_root_dref('empl_number', 3);
    ...
    print get_value_for_dref($report, 'employees.(#empl_number).name');

=over 4

=item resolve_pragmas( $dref_with_embedded_parens ) : $dref

=item resolve_pragmas( $dref_with_embedded_parens ) : ($dref, %options)

Calling resolve_pragmas() causes these expressions to be evaluated,
and an expanded version of the dref is returned. In a list context, also
returns a list of key-value pairs that may contain pragma information.

=over 4

=item (#I<dref>)

Parenthesized expressions begining with $DRefPrefix, the "#" character
by default, are replaced with the Root-relative value for that I<dref>
using get_value_for_root_dref().

=item (!I<flag>)

A flag indicating some optional or accessory behavior. Removed from the
string. Sets $options{I<flag>} to 1.

=back

=back


=head2 DRef Access

These functions provide the main public interface for dref-based access to 
values in nested data structures. They invoke the equivalent 
..._value_for_keys() function after expanding and spliting the provided drefs.  

Using these functions, you could replace the above statements with:

    print get_value_for_dref( $report, 'employees.3.id' );
    set_value_for_dref( $report, 'employees.3.name', 'Joe' );

=over 4

=item get_value_for_dref($target, $dref) : $value

Resolve pragmas and split the provided dref, then use get_value_for_keys
to look those keys up starting with target.

=item set_value_for_dref($target, $dref, $value)

Resolve pragmas and split the provided dref, then use set_value_for_keys.

=back


=head2 Shared Data Graph Entry

Data::DRef also provides a common point-of-entry datastructure, refered to
as $Root. Objects or structures accessible through $Root can be refered
to identically from any package using the get_value_for_root_dref and
set_value_for_root_dref functions. Here's another example:

    set_value_for_root_dref('report', $report);
    print get_value_for_root_dref('report.employees.3.name');

=over 4

=item $Root 

The data graph entry point, by default a reference to an anonymous hash.

=item get_value_for_root_dref($dref) : $value

Returns the value for the provided dref, starting at the root.

=item set_value_for_root_dref($dref, $value) : $value

Sets the value for the provided dref, starting at the root.

=item get_value_for_optional_dref($literal_or_prefixed_dref) : $value

If the argument begins with $DRefPrefix, the "#" character by default,
the remainder is passed through get_value_for_root_dref(); otherwise it
is returned unchanged.

=back


=head2 Select by DRefs

The selection functions extract and return elements of a collection by
evaluating them against a provided hash of criteria. When called in a
scalar context, they will return the first sucessful match; in a list
context, they will return all sucessful matches.

The keys in the criteria hash are drefs to check for each candidate;
a match is sucessful if for each of the provided drefs, the candidate
returns the same value that is associated with that dref in the criteria
hash. To check the value itself, rather than looking up a dref, use
undef as the hash key.

=over 4

=item matching_keys($target, %dref_value_criteria_pairs) : $key or @keys

Returns keys of the target whose corresponding values match the provided
criteria.

=item matching_values($target, %dref_value_criteria_pairs) : $item or @items

Returns values of the target which match the provided criteria. 

=back


=head2 Index by DRefs

The indexing functions extract the values from some target structure,
then return a new structure containing references to those same values.

=over 4

=item index_by_drefs($target, @drefs) : $index

Generates a hash, or series of nested hashes, of arrays containing values
from the target. A single dref argument produces a single-level index,
a hash which maps each value obtained to an array of values which returned
them; multiple dref arguments create nested hashes.

=item unique_index_by_drefs($target, @drefs) : $index

Similar to index_by_drefs, except that only the most-recently visited
single value is stored at each point in the index, rather than an array.

=item ordered_index_by_drefs( $target, $index_dref ) : $entry_ary

Constructs a single-level index while preserving the order in which
top-level index keys are discovered. An array of hashes is returned,
each containing one of the index keys and the array of associated values.

=back


=head2 DRefs to Leaf nodes

These functions explore all of the references in the network of structures
accessible from some starting point, and provide access to the outermost
(non-reference) items. For a tree structure, this is equivalent to listing
the leaf nodes, but these functions can also be used in structures with
circular references.

=over 4

=item leaf_drefs($target) : @drefs

Returns a list of drefs to the outermost values.

=item leaf_values( $target ) : @values

Returns a list of the outermost values.

=item leaf_drefs_and_values( $target ) : %dref_value_pairs

Returns a flat hash of the outermost drefs and values.

=back

=head2 Compatibility

To provide compatibility with earlier versions of this module, many of
the functions above are also accesible through an alias with the old name.


=head1 EXAMPLES

Here is a sample data structure which will be used to illustrate various
example function calls. Note that the individual hashes shown below are
only refered to in the following example results, not completely copied.

  $spud : { 
    'type'=>'tubers', 'name'=>'potatoes', 'color'=>'red', 'size'=>[2,3,5] 
  } 
  $apple : { 
    'type'=>'fruit', 'name'=>'apples', 'color'=>'red', 'size'=>[2,2,2] 
  }
  $orange : {
    'type'=>'fruit', 'name'=>'oranges', 'color'=>'orange', 'size'=>[1,1,1] 
  }
  
  $produce_info : [ $spud, $apple, $orange, ];

=head2 Select by DRefs

  matching_keys($produce_info, 'type'=>'tubers') : ( 0 )
  matching_keys($produce_info, 'type'=>'fruit') : ( 1, 2 )
  matching_keys($produce_info, 'type'=>'fruit', 'color'=>'red' ) : ( 1 )
  matching_keys($produce_info, 'type'=>'tubers', 'color'=>'orange' ) : ( )

  matching_values($produce_info, 'type'=>'fruit') : ( $apple, $orange )
  matching_values($produce_info, 'type'=>'fruit', 'color'=>'red' ) : ( $apple )

=head2 Index by DRefs

  index_by_drefs($produce_info, 'type') : { 
    'fruit' =>  [ $apple, $orange ],
    'tubers' => [ $spud ],
  }
  
  index_by_drefs($produce_info, 'color', 'type') : {
    'red' => { 
      'fruit' => [ $apple ],
      'tubers' => [ $spud ],
    },
    'orange' => { 
      'fruit' => [ $orange ],
    },
  }

  unique_index_by_drefs($produce_info, 'type') : { 
    'fruit' => $orange,
    'tubers' => $spud,
  }

  ordered_index_by_drefs($produce_info, 'type') : [
    {
      'value' => 'tubers',
      'items' => [ $spud ],
    },
    {
      'value' => 'fruit',
      'items' => [ $orange, $apple ],
    },
  ]

=head2 DRefs to Leaf nodes

  leaf_drefs($spud) : ( 'type', 'name', 'color', 'size.0', 'size.1', 'size.2' )

  leaf_values($spud) : ( 'tubers', 'potatoes', 'red', '2', '3', '5' )

  leaf_drefs_and_values($spud) : ( 
    'type' => 'tubers', 'name' => 'potatoes', 'color' => 'red', 
    'size.0' => 2, 'size.1' => 3, 'size.2' => 5
  )

=head2 Object Overrides

Here's a get_value_for_key method for an object which provides a
calculated timestamp value:

    package Clock;
    
    sub new { bless { @_ }; }
    
    sub m_get_value_for_key {
      my ($self, $key) = @_;
      return time() if ( $key eq 'timestamp' );
      return $self->{ $key };
    }
    
    package main;
    
    set_value_for_root_dref( 'clock', new Clock ( name => "Clock 1" ) );
    ...
    print get_value_for_root_dref('clock.timestamp');


=head1 STATUS AND SUPPORT

This release of Data::DRef is intended for public review and feedback.
This is the most recent version of code that has been used for several
years and thoroughly tested, however, the interface has recently been
overhauled and it should be considered "alpha" pending that feedback.

  Name            DSLI  Description
  --------------  ----  ---------------------------------------------
  Data::
  ::DRef          adph  Nested data access using delimited strings

You will also need the String::Escape module from CPAN or
www.evoscript.com.

Further information and support for this module is available at
E<lt>www.evoscript.comE<gt>.

Please report bugs or other problems to E<lt>bugs@evoscript.comE<gt>.

There is one known bug in this version:

=over 4

=item *

We don't always properly escape and unescape special characters within
DRef strings or protect $Separators embedded within a subkey. This is
expected to change soon.

=back

There is one major change under consideration:

=over 4

=item *

Perhaps a minimal method-based implementation similar to that used in
Data::DRef::MethodBased should be exported to UNIVERSAL, rather than
requiring all sorts of unrelated classes to establish a dependancy on
this module.  Prototype checking might prove to be useful here.

=back


=head1 AUTHORS AND COPYRIGHT

Copyright 1996, 1997, 1998, 1999 Evolution Online Systems, Inc. E<lt>www.evolution.comE<gt>

You may use this software for free under the terms of the Artistic License. 

Contributors: 
M. Simon Cavalletto E<lt>simonm@evolution.comE<gt>,
E. J. Evans E<lt>piglet@evolution.comE<gt>

=cut
