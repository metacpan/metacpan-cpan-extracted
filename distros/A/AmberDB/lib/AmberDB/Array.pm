package AmberDB::Array;

use 5.016;
use warnings;
use Carp qw(croak cluck);

our $VERSION = '5.25.1';
my $CREATED = '2018-02-23';

# TODO
# ...

# my $Array = $run->use_module("AmberDB::Array");
# ------------------------------------------------
sub new {

    my $class = shift;

    my %input = @_;

    # Load inputs.
    my $self = {};
    foreach ( keys %input ) {
        $self->{ uc($_) } = $input{$_};
    }

    bless $self, $class;
    return $self;
}

# my @list = qw/item1 item2 item3 item1 item2/;
# my @nodup = $Array->array_nodup(@list);
# deletes duplicates without breaking the list order
# ------------------------------------------------
sub array_nodup {

    my $self = shift;

    # Fast path when passed an array reference: avoids Perl stack copying
    if ( @_ == 1 && ref( $_[0] ) eq 'ARRAY' ) {
        my %exist;
        my @res = grep { defined($_) && $_ ne '' && !$exist{$_}++ } @{ $_[0] };
        return wantarray ? @res : \@res;
    }

    scalar @_ or return;

    my %exist;
    my @arrays = grep { defined($_) && $_ ne '' && !$exist{$_}++ } @_;

    return @arrays;
}

# my $a1 = [ qw/a b c d e/ ];
# my $a2 = [ qw/b c d f g/ ];
# my $a3 = [ qw/c d h i/ ];
# my $cropped = $Array->array_crop($a1, $a2, $a3);
# find intersection areas of lists (Shortest-List-First with early-exit)...
# ------------------------------------------------
sub array_crop {

    my ( $self, @arrays ) = @_;

    scalar @arrays or return [];

    # Ensure all elements are array references; if any is empty or not an ARRAY, intersection is empty
    for my $arr (@arrays) {
        return [] unless ref($arr) eq 'ARRAY' && @$arr;
    }

    if ( @arrays == 1 ) {
        my %seen;
        my @res = grep { defined($_) && $_ ne '' && !$seen{$_}++ } @{ $arrays[0] };
        return \@res;
    }

    # Shortest-List-First: Sort arrays by element count ascending
    @arrays = sort { scalar(@$a) <=> scalar(@$b) } @arrays;

    my $smallest = shift @arrays;
    my %candidates;
    foreach my $item (@$smallest) {
        $candidates{$item} = 1 if defined $item && $item ne '';
    }
    return [] unless %candidates;

    # Sequentially filter candidates against subsequent arrays
    foreach my $arr (@arrays) {
        my %seen;
        foreach my $item (@$arr) {
            $seen{$item} = 1 if defined $item;
        }
        foreach my $cand ( keys %candidates ) {
            delete $candidates{$cand} unless exists $seen{$cand};
        }
        return [] unless %candidates; # Early exit if intersection is empty
    }

    # Reconstruct result maintaining order of the smallest array (deduplicated)
    my %emitted;
    my @result = grep { exists $candidates{$_} && !$emitted{$_}++ } @$smallest;

    return \@result;
}

# my $l1 = [ qw/a b c/ ];
# my $l2 = [ qw/c d e/ ];
# my $l3 = [ qw/e f g/ ];
# my $merged = $Array->array_add($l1, $l2, $l3);
# merges lists without duplicates...
# ------------------------------------------------
sub array_add {

    my @result;
    my $exist = {};
    my ( $self, @arrays ) = @_;

    scalar @arrays or return [];

    foreach my $liste (@arrays) {
        ref($liste) eq 'ARRAY' or next;
        foreach my $list (@$liste) {
            if ( $exist->{$list} ) { next }
            $exist->{$list} = 1;
            push @result, $list;
        }
    }

    return \@result;
}

# my $kalan = $Array->array_punch($liste1, $liste2, $liste3);
# subtracts items in subsequent lists from first list (single-pass)...
# ------------------------------------------------
sub array_punch {

    my ( $self, $array, @arrays ) = @_;

    $array or return [];
    ref($array) eq 'ARRAY' or return [];

    my %exclude;
    foreach my $liste (@arrays) {
        next unless ref($liste) eq 'ARRAY';
        foreach my $part (@$liste) {
            $exclude{$part} = 1 if defined $part;
        }
    }

    my %seen;
    my @result;
    foreach my $part (@$array) {
        next if !defined $part || exists $exclude{$part} || $seen{$part}++;
        push @result, $part;
    }

    return \@result;
}

# my $l1 = [ qw/a b c d e/ ];
# my $l2 = [ qw/b c/ ];
# my $l3 = [ qw/d/ ];
# my $diff = $Array->array_substr($l1, $l2, $l3);
# removes later ones from first list...
# ------------------------------------------------
sub array_substr {

    my ( $self, $array, @arrays ) = @_;

    my @result;
    my $exist  = {};
    my $array1 = $array;
    foreach my $field (@$array1) {
        $exist->{$field} = 1;
    }
    foreach my $liste (@arrays) {
        ref($liste) eq 'ARRAY' or next;
        foreach my $field (@$liste) {
            delete( $exist->{$field} );
        }
    }
    foreach my $field (@$array1) {
        $exist->{$field} or next;
        push @result, $field;
    }

    return \@result;
}

# to use perl code as a filter
# @arrays = $Array->array_filter($predicate, @arrays);
# $predicate can be a CODE reference (preferred) or a string (deprecated).
# ------------------------------------------------
sub array_filter {

    my ( $self, $predicate, @arrays ) = @_;

    $predicate or return @arrays;

    # CODE reference path: secure, fast, no eval overhead
    if ( ref($predicate) eq 'CODE' ) {
        return grep { $predicate->($_) } @arrays;
    } else {
        return @arrays;
    }
}

# my $l1 = [ qw/a b c d e/ ];
# my $sub = $Array->array_substrno($l1, 2, 4);
# removes given list entry numbers from the list...
# ------------------------------------------------
sub array_substrno {

    my ( $self, $arraydata, @arraydel ) = @_;
    my %arraydel = map { $_ => 1 } @arraydel;

    my @result;
    for ( my $i = 0 ; $i < @$arraydata ; $i++ ) {
        next if ( $arraydel{$i} );
        push @result, $arraydata->[$i];
    }

    return \@result;
}

# TODO: check and test
# my $l1 = [ qw/a b c/ ];
# my $l2 = [ qw/a b c/ ];
# my $ok = $Array->array_compare($l1, $l2);
# compare two array...
# ------------------------------------------------
sub array_compare {

    my ( $self, $array1, $array2 ) = @_;

    scalar @$array1 == scalar @$array2 or return 0;

    for ( my $i = 0 ; $i < scalar @$array1 ; $i++ ) {
        return 0 if ( $array1->[$i] ne $array2->[$i] );
    }

    return 1;
}

# Finds the longest in sublists...
# my @new_list = $Array->array_sublist($deep, @records);
# ------------------------------------------------
sub array_sublist {

    my ( $self, $deep, @records ) = @_;

    $deep =~ /^(2|3|4|6|12)$/ or $deep = 2;

    my @result;
    for ( my $i = 0 ; $i < @records ; $i += $deep ) {
        my @line;
        for ( my $j = 0 ; $j < $deep ; $j++ ) {
            push @line, $records[ $i + $j ] // "";
        }
        push @result, \@line;
    }

    return @result;
}

# gets the size of list matrix...
# ------------------------------------------------
sub array_size {

    my ( $self, @lines ) = @_;

    my $max_line = scalar @lines;
    $max_line or return 0;

    my $max_blok = 1;
    foreach my $line (@lines) {
        ref $line eq "ARRAY" or next;
        my $fld = scalar @$line;
        $max_blok = $fld > $max_blok ? $fld : $max_blok;
    }

    return ( ( $max_line - 1 ), ( $max_blok - 1 ) );
}

# my @picked = $adb->array_pick($indexes, @record);
# takes blocks at given index list to build a new list.
# ------------------------------------------------
sub array_pick {

    my ( $self, $indexes, @record ) = @_;

    ref($indexes) eq 'ARRAY' or return ();
    @record or return ();

    return map { $record[$_] } @$indexes;
}

# my $array2 = $adb->deep_copy($array);
# ------------------------------------------------
sub deep_copy {
    my ( $self, $src ) = @_;

    if (ref $src eq 'HASH') {
        return { map { $_ => $self->deep_copy($src->{$_}) } keys %$src };
    } elsif (ref $src eq 'ARRAY') {
        return [ map { $self->deep_copy($_) } @$src ];
    } else {
        return $src;  # scalar, undef, number etc.
    }
}

# Non-destructively compares two hash references and returns key differences.
# my $diff = $adb->hash_diff($hash1, $hash2);
# Returns: { hash1 => { keys only in hash1 }, hash2 => { keys only in hash2 } }
# ------------------------------------------------
sub hash_diff {
    my ( $self, $hash1, $hash2 ) = @_;

    $hash1 = {} unless defined $hash1 && ref($hash1) eq 'HASH';
    $hash2 = {} unless defined $hash2 && ref($hash2) eq 'HASH';

    my %h1 = %$hash1;
    my %h2 = %$hash2;

    foreach my $key ( keys %h1 ) {
        if ( exists $h2{$key} ) {
            delete $h1{$key};
            delete $h2{$key};
        }
    }

    my %diff;
    $diff{hash1} = \%h1 if keys %h1;
    $diff{hash2} = \%h2 if keys %h2;

    return \%diff;
}


# shuffles the list order and creates a new list.
# ------------------------------------------------
sub array_shuffle {

    my ( $self, @array ) = @_;
    for my $i ( reverse 1 .. $#array ) {
        my $r = int rand( $i + 1 );
        @array[ $i, $r ] = @array[ $r, $i ];
    }
    return @array;
}

# inverts the list matrix...
# ------------------------------------------------
sub inverse_matrix {

    my ( $self, @lines ) = @_;

    my @result;
    my ( $max_line, $max_blok ) = $self->array_size(@lines);

    for my $i ( 0 .. $max_line ) {
        if ( ref $lines[$i] ne "ARRAY" ) {
            $lines[$i] = [ $lines[$i] ];
        }
        for my $j ( 0 .. $max_blok ) {
            $result[$j][$i] = $lines[$i][$j];
        }
    }

    return @result;
}

# Generalized array sorting function.
# my @sorted = $Array->array_sort($type, $direct, $field, @records);
# my @sorted = $Array->array_sort($type, $direct, $field, \@records);
# Parameters:
#   $type:   'num' (numeric comparison <=>) or 'ascii' (string comparison cmp). Auto-detects if undef.
#   $direct: 0 / 'asc' / undef (ascending) or 1 / 'desc' / 'reverse' / '-' (descending / reversed).
#   $field:  element column/block index (e.g. 0, 1, 2) when elements are ARRAY refs. If defined 0: compares $a->[0] and $b->[0].
#   @records: list of scalars or list of array references.
# ------------------------------------------------
sub array_sort {

    my ( $self, $type, $direct, $field, @records ) = @_;

    # Support passing a single array reference of records
    if ( @records == 1 && ref( $records[0] ) eq 'ARRAY' && !defined $field ) {
        @records = @{ $records[0] };
    }

    return () unless @records;

    # Normalize direction: 1, 'desc', 'reverse', '-' => descending
    my $is_desc = ( defined $direct && ( $direct eq '1' || lc($direct) eq 'desc' || lc($direct) eq 'reverse' || $direct eq '-' ) ) ? 1 : 0;

    # Check if elements are ARRAY refs
    my $is_aoa = ( ref( $records[0] ) eq 'ARRAY' ) ? 1 : 0;

    # If field is not defined but elements are ARRAY refs, default field to 0
    if ( !defined $field && $is_aoa ) {
        $field = 0;
    }

    # Normalize and auto-detect type
    $type = lc( $type // '' );
    if ( !$type || $type eq 'auto' ) {
        my $sample = defined $field
            ? ( ( ref( $records[0] ) eq 'ARRAY' ) ? $records[0]->[$field] : $records[0] )
            : $records[0];
        $type = ( defined $sample && $sample =~ /^-?[0-9]+(?:\.[0-9]+)?$/ ) ? 'num' : 'ascii';
    }
    my $is_num = ( $type eq 'num' || $type eq 'numeric' || $type eq 'int' || $type eq 'float' || $type eq 'decimal' ) ? 1 : 0;

    # Sorting execution
    if ( defined $field && $is_aoa ) {
        if ($is_num) {
            @records = $is_desc
                ? sort { ( $b->[$field] // 0 ) <=> ( $a->[$field] // 0 ) } @records
                : sort { ( $a->[$field] // 0 ) <=> ( $b->[$field] // 0 ) } @records;
        }
        else {
            @records = $is_desc
                ? sort { ( $b->[$field] // '' ) cmp ( $a->[$field] // '' ) } @records
                : sort { ( $a->[$field] // '' ) cmp ( $b->[$field] // '' ) } @records;
        }
    }
    else {
        if ($is_num) {
            @records = $is_desc
                ? sort { ( $b // 0 ) <=> ( $a // 0 ) } @records
                : sort { ( $a // 0 ) <=> ( $b // 0 ) } @records;
        }
        else {
            @records = $is_desc
                ? sort { ( $b // '' ) cmp ( $a // '' ) } @records
                : sort { ( $a // '' ) cmp ( $b // '' ) } @records;
        }
    }

    return wantarray ? @records : \@records;
}

1;

__END__

=head1 NAME

AmberDB::Array - Array, matrix manipulation, and set operations utility

=head1 SYNOPSIS

  # 1. Direct usage via AmberDB instance ($adb inherits AmberDB::Array):
  my @unique     = $adb->array_nodup(@raw_list);
  my $common_ids = $adb->array_crop($list1, $list2, $list3);
  my @sorted     = $adb->array_sort('num', 'desc', 0, @records);
  my $cloned     = $adb->deep_copy($nested_data);

  # 2. Standalone usage:
  use AmberDB::Array;
  my $array_util = AmberDB::Array->new();
  my @unique     = $array_util->array_nodup(@raw_list);

=head1 DESCRIPTION

C<AmberDB::Array> provides a rich set of utility methods for array manipulation, set operations (union, intersection, difference), matrix transformations, filtering, multi-dimensional array sorting, and deep copying.

B<Inheritance Note:> C<AmberDB> inherits from C<AmberDB::Array> via C<use parent>. All methods documented below can be invoked directly on any C<$adb> instance (e.g. C<$adb-E<gt>array_nodup(...)>), as well as on standalone C<AmberDB::Array> objects.

=head1 METHODS

=head2 array_nodup(@list)

Removes duplicate elements from C<@list> while strictly preserving original insertion order.

  my @tags = $adb->array_nodup("perl", "db", "perl", "nosql", "db");
  # => ("perl", "db", "nosql")

=head2 array_crop($arr1, $arr2, ...)

Computes the mathematical intersection of two or more array references. Returns an array reference containing only elements present in B<all> provided lists.

  my $list1 = [ "apple", "banana", "cherry" ];
  my $list2 = [ "banana", "cherry", "date" ];
  my $common = $adb->array_crop($list1, $list2);
  # => [ "banana", "cherry" ]

=head2 array_add($arr1, $arr2, ...)

Merges multiple array references into a single unified array reference without duplicates (union), preserving appearance order.

  my $merged = $adb->array_add([ 1, 2, 3 ], [ 3, 4, 5 ], [ 5, 6 ]);
  # => [ 1, 2, 3, 4, 5, 6 ]

=head2 array_punch($primary_arr, @other_arrs)

Subtracts all elements found in subsequent array references (C<@other_arrs>) from the primary array reference (C<$primary_arr>). Returns an array of remaining elements with duplicates removed.

  my $primary = [ "a", "b", "c", "d", "e" ];
  my $exclude = [ "b", "d" ];
  my @remaining = $adb->array_punch($primary, $exclude);
  # => ("a", "c", "e")

=head2 array_substr($primary_arr, @other_arrs)

Removes elements of subsequent array references from C<$primary_arr>, returning an array reference of the difference. Unlike C<array_punch>, preserves duplicates within the primary list if not present in the subtractors.

  my $diff = $adb->array_substr([ "a", "b", "c", "a" ], [ "b" ]);
  # => [ "a", "c", "a" ]

=head2 array_filter($predicate, @arrays)

Filters an array using a C<CODE> reference predicate. Executes fast and safe in-memory filtering without eval overhead.

  my @evens = $adb->array_filter(sub { $_[0] % 2 == 0 }, 1, 2, 3, 4, 5, 6);
  # => (2, 4, 6)

=head2 array_substrno($arraydata, @indices_to_remove)

Removes elements at specified 0-based indices from an array reference.

  my $data = [ "first", "second", "third", "fourth" ];
  my $sub  = $adb->array_substrno($data, 1, 3);
  # => [ "first", "third" ]

=head2 array_compare($arr1, $arr2)

Performs an element-by-element string comparison between two array references. Returns C<1> if both arrays are identical in length and values, C<0> otherwise.

  my $same = $adb->array_compare([ 1, "test" ], [ 1, "test" ]); # 1
  my $diff = $adb->array_compare([ 1, "test" ], [ 2, "test" ]); # 0

=head2 array_sublist($chunk_size, @records)

Splits a flat list into an array of sub-lists (chunks), each containing C<$chunk_size> items (valid chunk sizes: 2, 3, 4, 6, 12; default is 2).

  my @matrix = $adb->array_sublist(2, "a", "b", "c", "d");
  # => ( ["a", "b"], ["c", "d"] )

=head2 array_size(@lines)

Calculates the dimensions of a list of array references (matrix). Returns a 2-element list: C<($max_row_index, $max_column_index)>.

  my ($max_row, $max_col) = $adb->array_size( [1, 2, 3], [4, 5] );
  # => (1, 2)  # 2 rows (0..1), 3 columns (0..2)

=head2 array_pick(\@indexes, @record)

Extracts and returns only the fields at the given 0-based index positions from C<@record>.

  my @selected = $adb->array_pick([ 0, 2 ], "ID101", "SecretKey", "PublicTitle");
  # => ("ID101", "PublicTitle")

=head2 deep_copy($data)

Recursively clones nested Perl data structures (hash references, array references, and scalar values) to produce an independent copy.

  my $copy = $adb->deep_copy({ user => { roles => [ "admin", "editor" ] } });

=head2 hash_diff($hash1, $hash2)

Non-destructively compares two hash references and returns a hash reference containing the keys unique to each input hash. The original hash structures are preserved unmodified.

  my $h1 = { a => 1, b => 2, c => 3 };
  my $h2 = { b => 2, c => 3, d => 4 };
  my $diff = $adb->hash_diff($h1, $h2);
  # => { hash1 => { a => 1 }, hash2 => { d => 4 } }

=head2 array_shuffle(@array)

Shuffles the order of elements randomly using the Fisher-Yates algorithm and returns the new list.

  my @randomized = $adb->array_shuffle(1, 2, 3, 4, 5);

=head2 inverse_matrix(@lines)

Transposes a two-dimensional matrix (swaps rows and columns).

  my @transposed = $adb->inverse_matrix(
      [ "r1c1", "r1c2" ],
      [ "r2c1", "r2c2" ]
  );
  # => ( [ "r1c1", "r2c1" ], [ "r1c2", "r2c2" ] )

=head2 array_sort($type, $direct, $field, @records)

Versatile array and matrix sorting engine. Supports scalar lists as well as array-of-arrays (AoA) records.

=over 4

=item * C<$type>: C<'num'> (numeric C<E<lt>=E<gt>>) or C<'ascii'> (string C<cmp>). Set to C<undef> or C<'auto'> for automatic detection.

=item * C<$direct>: C<0>, C<'asc'>, or C<undef> for ascending; C<1>, C<'desc'>, C<'reverse'>, or C<'-'> for descending.

=item * C<$field>: Column/block index (0-based) when sorting array references. If sorting scalars, pass C<undef>.

=item * C<@records>: List of scalars or array references to sort (can also be passed as a single C<\@records> arrayref).

=back

Context-aware: Returns a list in list context or an array reference in scalar context.

  # 1. Simple numeric descending sort
  my @sorted_nums = $adb->array_sort('num', 'desc', undef, 10, 5, 20, 1);
  # => (20, 10, 5, 1)

  # 2. Sorting records by column index 1 ascending
  my @records = (
      [ 101, "Zebra", 50 ],
      [ 102, "Apple", 20 ],
      [ 103, "Mango", 80 ]
  );
  my @by_name = $adb->array_sort('ascii', 'asc', 1, @records);
  # => ([102, "Apple", 20], [103, "Mango", 80], [101, "Zebra", 50])

  # 3. Sorting records by column index 2 numeric descending
  my @by_price = $adb->array_sort('num', 'desc', 2, @records);

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2018-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut
