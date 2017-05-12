=head1 NAME

Data::Sorting - Multi-key sort using function results


=head1 SYNOPSIS

  use Data::Sorting qw( :basics :arrays :extras );
  
  # Sorting functions default to simple string comparisons 
  @names = qw( Bob Alice Ellen Charlie David );
  @ordered = sorted_by( undef, @names );
  
  # Various options can be passed before the list values
  @ordered = sorted_by( [ -order=>'reverse' ], @names );

  # You can also generate a sorting function and then apply it
  $function = sort_function(); 
  @ordered = $function->( @names );  # or &{$function}(@names)
  @ordered = sort_function( -order=>'reverse' )->( @names );
  
  # The :array functions are prototyped to take the array first
  @ordered = sorted_array( @names );
  @ordered = sorted_arrayref( \@names );

  # You can also sort an array in place, changing its internal order
  sort_array( @names );
  sort_arrayref( \@names );
  
  # There are several sorting options, such as -compare => 'natural'
  @movies = ( 'The Matrix', 'Plan 9', '2001', 'Terminator 2' );
  @ordered = sort_function( -compare => 'natural' )->( @movies );
  # @ ordered now contains '2001', 'The Matrix', 'Plan 9', 'Terminator 2'
  
  # To sort numbers, pass the -compare => 'numeric' option
  @numbers = ( 18, 5, 23, 42, 156, 91, 64 );
  @ordered = sorted_by( [ -compare => 'numeric' ], @numbers );
  @ordered = sort_function( -compare => 'numeric' )->( @numbers );
  @ordered = sorted_array( @numbers, -compare => 'numeric' );
  sort_array( @numbers, -compare => 'numeric' );
  
  # You can sort by the results of a function to be called on each item
  sort_array( @numbers, -compare => 'numeric', sub { $_[0] % 16 } );
  # @numbers now contains 64, 18, 5, 23, 42, 91, 156
  
  # For arrays of datastructures, pass in keys to extract for sorting
  @records = ( 
    { 'rec_id'=>3, 'name'=>{'first'=>'Bob', 'last'=>'Macy'} },
    { 'rec_id'=>1, 'name'=>{'first'=>'Sue', 'last'=>'Jones'} },
    { 'rec_id'=>2, 'name'=>{'first'=>'Al',  'last'=>'Jones' } },
  );
  @ordered = sorted_array( @records, 'rec_id' );

  # For nested data structures, pass an array of keys to fetch
  @ordered = sorted_array( @records, ['name','first'] );

  # Pass multiple sort keys for multiple-level sorts
  @ordered = sorted_array( @records, ['name','last'], ['name','first'] );
  
  # Any selected sort options are applied to all subsequent sort keys
  @ordered = sorted_array( @records, 
		-order => 'reverse', ['name','last'], ['name','first'] );
  
  # Options specified within a hash-ref apply only to that key
  @ordered = sorted_array( @records, 
		{ order=>'reverse', sortkey=>['name','last'] }, 
		['name','first'] );
  
  # Locale support is available if you have Perl 5.004 or later and POSIX
  POSIX::setlocale( POSIX::LC_COLLATE(), 'en_US' );
  POSIX::setlocale( POSIX::LC_CTYPE(), 'en_US' );
  @ordered = sorted_array( @records, 
		 -compare=>'locale', ['name','last'], ['name','first'] );


=head1 ABSTRACT

Data::Sorting provides functions to sort the contents of arrays based on a collection of extraction and comparison rules. Extraction rules are used to identify the attributes of array elements on which the ordering is based; comparison rules specify how those values should be ordered.

Index strings may be used to retrieve values from array elements, or function references may be passed in to call on each element. Comparison rules are provided for numeric, bytewise, and case-insensitive orders, as well as a 'natural' comparison that places numbers first, in numeric order, followed by the remaining items in case-insensitive textual order.


=head1 DESCRIPTION

This module provides several public functions with different calling interfaces that all use the same underlying sorting mechanisms. 

These functions may be imported individually or in groups using the following tags:

=over 9

=item :basics

sorted_by(), sort_function(): General-purpose sorting functions.

=item :array

sorted_array(), sorted_arrayref(), sort_array(), sort_arrayref(): Prototyped functions for arrays.

=item :extras

sort_key_values(), sort_description(): Two accessory functions that explain how sorting is being carried out.

=back

All of these functions take a list of sorting rules as arguments. See L<"Sort Rule Syntax"> for a discussion of the contents of the $sort_rule or @sort_rules parameters shown below.

=cut

########################################################################

package Data::Sorting;

require 5.003;
use strict;
use Carp;
use Exporter;

use vars qw( $VERSION @ISA %EXPORT_TAGS );
$VERSION = 0.9;

push @ISA, qw( Exporter );
%EXPORT_TAGS = (
  basics =>  [qw( sorted_by sort_function )],
  arrays =>  [qw( sorted_array sorted_arrayref sort_array sort_arrayref)],
  extras =>  [qw( sort_key_values sort_description )],
);
Exporter::export_ok_tags( keys %EXPORT_TAGS );

use vars qw( @Array @Rules $PreCalculate $Rule @ValueSet );

########################################################################

=head2 sorted_by

  @ordered = sorted_by( $sort_rule, @value_array );
  @ordered = sorted_by( $sort_rule, @$value_arrayref );  
  @ordered = sorted_by( $sort_rule, $value1, $value2, $value3 );

  @ordered = sorted_by( \@sort_rules, @value_array );
  @ordered = sorted_by( \@sort_rules, @$value_arrayref );  
  @ordered = sorted_by( \@sort_rules, $value1, $value2, $value3 );

This is a general-purpose sorting function which accepts one or more sort order rules and a list of input values, then returns the values in the order specified by the rules. 

=cut

# @in_order = sorted_by( $sort_rules_ary, @values );
sub sorted_by ($;@) { 
  my @sort_params = ( ! defined $_[0] )       ? () : 
		    ( ref($_[0]) eq 'ARRAY' ) ? @{ (shift) } : 
						shift;
  ( my $sorter, local @Rules ) = _parse_sort_args( @sort_params );
  local *Array = \@_;
  &$sorter;
}

########################################################################

=head2 sort_function

  @ordered = sort_function( @sort_rules )->( @value_array );
  @ordered = sort_function( @sort_rules )->( @$value_arrayref );
  @ordered = sort_function( @sort_rules )->( $value1, $value2, $value3 );

Creates an anonymous function which applies the provided sort rules. The function may be cached and used multiple times to apply the same rules again.

=cut

# @in_order = sort_function( @sort_rules )->( @array );
sub sort_function (@) { 
  my ( $sorter, @rules ) = _parse_sort_args( @_ );
  return sub { 
    local *Array = \@_;
    local @Rules = @rules;
    my @results = &$sorter;
    # Kludge to clear extracted data; there's gotta be a better way...
    foreach my $rule (@rules) { 
      map { delete $rule->{$_} } grep /^ext_/, keys %$rule 
    }
    @results;
  } 
}

########################################################################

=head2 sorted_array

  @ordered = sorted_array( @value_array, @sort_rules );
  @ordered = sorted_array( @$value_arrayref, @sort_rules );

Returns a sorted list of the items without altering the order of the original list.

=cut

# @in_order = sorted_array( @array, @sort_rules );
sub sorted_array (\@;@) { 
  local *Array = shift;
  ( my $sorter, local @Rules ) = _parse_sort_args( @_ );
  &$sorter;
}

=head2 sorted_arrayref

  @ordered = sorted_arrayref( \@value_array, @sort_rules );
  @ordered = sorted_arrayref( $value_arrayref, @sort_rules );

Returns a sorted list of the items without altering the order of the original list.

=cut

# @in_order = sorted_arrayref( $array_ref, @sort_rules );
sub sorted_arrayref ($;@) { 
  local *Array = shift;
  ( my $sorter, local @Rules ) = _parse_sort_args( @_ );
  &$sorter;
}

########################################################################

=head2 sort_array

  sort_array( @value_array, @sort_rules );
  sort_array( @$value_arrayref, @sort_rules );

Sorts the contents of the specified array using a list of sorting rules. 

=cut

# sort_array( @array, @sort_rules );
sub sort_array (\@;@) { 
  local *Array = shift;
  ( my $sorter, local @Rules ) = _parse_sort_args( @_ );
  @Array = &$sorter;
}

=head2 sort_arrayref

  sort_arrayref( \@value_array, @sort_rules );
  sort_arrayref( $value_arrayref, @sort_rules );

Equivalent to sort_array, but takes an explicit array reference as its first argument, rather than an array variable.

=cut

# sort_arrayref( $array_ref, @sort_rules );
sub sort_arrayref ($;@) { 
  local *Array = shift;
  ( my $sorter, local @Rules ) = _parse_sort_args( @_ );
  @Array = &$sorter;
}

########################################################################

=head2 sort_key_values

  @key_values = sort_key_values( \@value_array, @sort_rules );
  @key_values = sort_key_values( $value_arrayref, @sort_rules );

Doesn't actually perform any sorting. Extracts and returns the values which would be used as sort keys from each item in the array, in their original order.

=cut

# @results = sort_key_values( $array, @sort_rules );
sub sort_key_values ($;@) {
  local *Array = shift;
  my ($sorter, @rules) = _parse_sort_args( @_ );
  
  if ( scalar @rules == 1  ) {
    _extract_values_for_rule( $rules[0], @Array );
  } else {
    map [ _extract_values_for_item( $_, @rules ) ], @Array;
  }
}

########################################################################

=head2 sort_description

  @description = sort_description( $descriptor, @sort_rules );

Doesn't actually perform any sorting. Provides descriptive information about the sort rules for diagnostic purposes.

=cut

# @sort_rules = sort_description( 'text', @sort_rules );
sub sort_description ($;@) {
  my $descriptor = shift;

  my $desc_func;
  if ( ! $descriptor ) {
    $desc_func = \&_desc_text;
  } elsif ( ref($descriptor) eq 'CODE' ) {
    $desc_func = $descriptor;
  } elsif ( ! ref($descriptor) ) {
    no strict 'refs';
    $desc_func = \&{"_desc_$descriptor"}
      or croak("Can't find a function named '_desc_$descriptor'");
  } else {
    croak("Unsupported descriptor '$descriptor'")
  } 
  
  my ($sorter, @rules) = _parse_sort_args( @_ );
  
  map { &$desc_func( $_ ) } @rules;
}

sub _desc_text {
  my $rule = shift;

  my $comp = $rule->{compare};
  
  $rule->{extract} .  

   join( '', map $_ ? "($_) " : " ", join(', ', map "'$_'", @{ $rule->{extract_args} }) ) . 

  "in " . ( $rule->{order_sign} < 0 ? "descending" : "ascending" ) . " " .
  
  ( ! ref($comp) ? "$comp" : 
	    ref($comp) eq 'CODE' ? "with custom function ($comp)": 
	    ref($comp) eq 'ARRAY' ? join(', ', @$comp) : "with $comp" ) .
   " order"
}

########################################################################

=head2 Sort Rule Syntax

The sort rule argument list may contain several different types of parameters, which are parsed identically by all of the public functions described above. 

A sort rule definition list may contain any combination of the following argument structures:

=over 4

=item I<nothing>

If no sort keys are specified, a default sort key is created using the C<extract =E<gt> "self"> option.

  @ordered = sorted_array( @names );

=item I<sortkey>

Specifies a sort key. Each I<sortkey> may be either a scalar value, or an array reference. Appropriate values for a I<sortkey> vary depending on which "extract" option is being used, and are discussed further below.

  @ordered = sorted_array( @numbers, sub { $_[0] % 8 } );
  @ordered = sorted_array( @records, 'rec_id' );
  @ordered = sorted_array( @records, ['name','first'] );

Any number of sortkeys may be provided:

  @ordered = sorted_array( @records, ['name','last'], 
				     ['name','first'] );

=item -sortkey => I<sortkey>

Another way of specifying a sort key is by preceding it with the "-sortkey" flag. 

  @ordered = sorted_array( @numbers, -sortkey => sub { $_[0] % 8 } );
  @ordered = sorted_array( @records, -sortkey => ['name','last'], 
				     -sortkey => ['name','first'] );

=item { sortkey => I<sortkey>, I<option> => I<option_value>, ... }

Additional options can be specified by passing a reference to a hash containing a sortkey and values for any number of options described in the list below.

  @ordered = sorted_array( @numbers, { sortkey => sub { abs(shift) },
				       compare => 'numeric',     } );

=item -I<option> => I<option_value>

Sets a default option for any subsequent sortkeys in the argument list.

  @ordered = sorted_array( @records, -compare => 'numeric', 
				     -sortkey => sub { abs(shift) });

  @ordered = sorted_array( @records, -compare => 'textual', 
				     -sortkey => ['name','last'], 
				     -sortkey => ['name','first'] );

=back

The possible I<option> values are:

=over 4

=item extract

Determines the function which will be used to retrieve the sort key value from each item in the input list.

=item compare

Determines the function which will be used to order the extracted values.

=item order

Can be set to "reverse" or "descending" to invert the sort order. Defaults to "ascending".

=item engine

Determines the underlying sorting algorithm which will be used to implement the sort. Generally left blank, enabling the module to select the best one available.

=back

Each of these options is discussed at further length below.

=cut

my @DefaultState = ( order=>'ascending', compare=>'cmp', extract=>'any' );
my %SupportedOptions = ( map { $_=>1 } qw( engine order compare extract ) );
my %FunctionCache;

sub _parse_sort_args {
  my @arguments = ( @_ );
  
  my %state;
  my @rules;
  while ( scalar @arguments ) {
    my $token = shift @arguments;
    
    my ( $flagname ) = ( $token =~ /^\-(\w+)$/ );
    if ( $flagname and $SupportedOptions{$flagname} ) {
      $state{ $flagname } = shift @arguments;
    } elsif ( $flagname eq 'sortkey' ) {
      push @rules, { @DefaultState, %state, 'sortkey' => shift @arguments };
    } elsif ( ref($token) eq 'HASH' ) {
      push @rules, { @DefaultState, %state, %$token };
    } else {
      push @rules, { @DefaultState, %state, 'sortkey' => $token };
    }
  }
  if ( ! scalar @rules ) { 
    push @rules, { @DefaultState, 'extract' => 'self', %state, sortkey => [] };
  }

  no strict 'refs';

  foreach my $rule ( @rules ) {
    # Select the appropriate comparison function
    my $compare = $rule->{compare};
    croak("Missing compare option for sorting") unless ( $compare );
    $rule->{compare_func} = ref($compare) eq 'CODE' ? $compare : 
	$FunctionCache{"_cmp_$compare"} ||= \&{"_cmp_$compare"} 
	|| croak("Can't find a function named '_cmp_$compare'");
    
    # Optional parameter for "reverse" or "descending" sorts
    $rule->{order_sign} = ( $rule->{order} =~ /^desc|^rev/i ) ? -1 : 1;
    
    # Select the appropriate value extraction function
    my $extract = $rule->{extract};
    croak("Missing extract option for sorting") unless ( length $extract );
    $extract = 'code' if ($extract eq 'any' && ref($rule->{sortkey}) eq 'CODE');
    $rule->{extract_func} = ref($extract) eq 'CODE' ? $extract : 
	$FunctionCache{"_ext_$extract"} ||= \&{"_ext_$extract"} || 
	croak("Can't find a function named '_ext_$extract'");
    
    # Optional array of arguments to the extraction function
    my $skey = $rule->{sortkey};
    $rule->{extract_args} = ( ! defined $skey )     ? [] : 
			    (ref($skey) eq 'ARRAY') ? $skey : 
						      [ $skey ];
    
    if ( $extract eq 'compound' ) {
      foreach ( 0 .. $#{ $rule->{extract_args} } / 2 ) {
	my $xa = $rule->{extract_args}->[ $_ * 2 ];
	if ( ! ref $xa ) {
	  $rule->{extract_args}->[$_ * 2] = $FunctionCache{"_ext_$xa"} ||=
	      \&{"_ext_$xa"} || croak("Can't find a function named '_ext_$xa'");
	}
      }
    }    
  }
  
  # If $PreCalculate is set, do our lookups ahead of time for all of the items
  my $engine = defined($PreCalculate) 				   ? 'precalc' : 
    		$rules[0]->{engine}  			 ? $rules[0]->{engine} : 
	    ( @rules == 1 and $rules[0]->{order_sign} > 0 
			  and $rules[0]->{compare} eq 'cmp' 
			  and $rules[0]->{extract} eq 'self' ) 	   ? 'trivial' : 
  (! grep {$_->{compare} ne 'cmp' or $_->{order_sign} < 0} @rules) ? 'packed'  : 
		( scalar @rules == 1 ) 				   ? 'precalc' :
								     'orcish'  ;
  # warn "Sorting using '$engine' engine\n";
  
  my $sorter = ref($engine) eq 'CODE' ? $engine :
	$FunctionCache{"_sorted_$engine"} ||= \&{"_sorted_$engine"} ||
    croak("No such sort mode '$engine'; can't find function '_sorted_$engine'");
  
  return $sorter, @rules;
}

########################################################################

=head2 Extraction Functions

For the extract option, you may specify one of the following I<option_value>s:

=over 4

=item any

The default. Based on the I<sortkey> may behave as the 'self', 'key', or 'method' options described below.

=item self

Uses the input value as the sort key, unaltered. Typically used when sorting strings or other scalar values.

=item key

Allows for indexing in to hash or array references, allowing you to sort a list of arrayrefs based on the I<n>th value in each, or to sort a list of hashrefs based on a given key.

If the sortkey is an array reference, then the keys are looked up sequentially, allowing you to sort on the contents of a nested hash or array structure.

=item method

Uses the sortkey as a method name to be called on each list value, enabling you to sort objects by some calculated value. 

If the sortkey is an array reference, then the first value is used as the method name and the remaining values as arguments to that method.

=item I<CODEREF>

You may pass in a reference to a custom extraction function that will be used to retrieve the sort key values for this rule. The function will be called separately for each value in the input list, receiving that current value as an argument.

If the sortkey is an array reference, then the first value is used as the function reference and the remaining values as arguments to be passed after the item value.

=back

    extract => self | method | key     | code    | CODEREF | ...
    sortkey => -    | m.name | key/idx | CODEREF | args

=cut

# $value = _extract_value( $item, $rule );
sub _extract_value {
  my ( $item, $rule ) = @_;
  my $value = &{ $rule->{extract_func} }( $item, @{ $rule->{extract_args} } );
  return defined($value) ? $value : '';
}

# $value = _extract_values_for_item( $item, @rules );
sub _extract_values_for_item {
  my $item = shift;
  map { defined($_) ? $_ : '' } 
    map { &{ $_->{extract_func} }( $item, @{ $_->{extract_args} } ) } @_;
}

# $value = _extract_values_for_rule( $rule, @item );
sub _extract_values_for_rule {
  my $rule = shift;
  return @_ if ( $rule->{extract} eq 'self' );
  map { defined($_) ? $_ : '' } 
    map { &{ $rule->{extract_func} }( $_, @{ $rule->{extract_args} } ) } @_;
}

sub _ext_self {
  my ( $item, @sortkey ) = @_;
  return $item;
}

sub _ext_split {
  my ( $item, $delim, @indexes ) = @_;
  # warn "Split '$item' with '$delim'\n";
  my @values = split /$delim/, $item;
  join $delim, @values[ @indexes ];
}

sub _ext_substr {
  my ( $item, @sortkey ) = @_;
  $#sortkey ? substr($item, $sortkey[0], $sortkey[1] ) : substr($item, $sortkey[0] );
}

sub _ext_self_code {
  my ( $item, @sortkey ) = @_;
  &$item( @sortkey );
}

sub _ext_code {
  my ( $item, $code, @sortkey ) = @_;
  &$code( $item, @sortkey );
}

sub _ext_method {
  my ( $item, $method, @sortkey ) = @_;
  $item->$method( @sortkey );
}

sub _ext_index {
  my ( $item, @sortkey ) = @_;
  while ( scalar @sortkey ) {
    my $index = shift @sortkey;

    if ( ! ref $item ) {
      return;
    } elsif ( UNIVERSAL::isa($item, 'HASH') ) {
      $item = $item->{$index};
    } elsif ( UNIVERSAL::isa($item, 'ARRAY') ) {
      carp "Use of non-numeric key '$index'" 
	unless ( $index eq '0' or $index != 0 );
      $item = $item->[$index];
    } else {
      carp "Can't _ext_index from '$item' ($index)";
    }

  }
  return $item;
}

sub _ext_any {
  my ( $item, @sortkey ) = @_;
  
  if ( ref($item) eq 'CODE' ) {
    # &_ext_self_code;
    &$item( @sortkey );
  } elsif ( ! scalar @sortkey  ) {
    return $item;
  } elsif ( ref($sortkey[0]) eq 'CODE' ) {
    &_ext_code;
  } elsif ( UNIVERSAL::can( $item, $sortkey[0] ) ) {
    &_ext_method;
  } elsif ( ! ref $sortkey[0]  ) {
    &_ext_index;
  } else {
    confess "Unsure how to extract value for sorting purposes";
  }
}

sub _ext_compound {
  my $item = shift;
  while ( scalar @_ ) { 
    my ($extr_sub, $sortkey) = ( shift, shift );
    $item = &$extr_sub( $item, $sortkey ? @$sortkey : () );
  }
  return $item;
}

########################################################################

=head2 Comparison Functions

For the compare option, you may specify one of the following I<option_value>s:

=over 4

=item cmp

The default comparison, using Perl's default cmp operator.

=item numeric

A numeric comparison using Perl's <=> operator.

=item textual

A text-oriented comparison that ignores whitespace and capitalization.

=item natural

A multi-type comparison that places empty values first, then numeric values in numeric order, then non-textual values like punctuation, followed by textual values in text order. The natural ordering also includes moving subsidiary words to the end, eg "The Book of Verse" is sorted as "Book of Verse, The"

=item locale : $three_way_cmp

Comparator functions which use the POSIX strcoll function for ordering.

=item lc_locale : $three_way_cmp

A case-insensitive version of the POSIX strcoll ordering.

=item num_lc_locale

Like the 'natural' style, this comparison distinguishes between empty and numeric values, but uses the lc_locale function to sort the textual values.

=item I<CODEREF>

You may pass in a reference to a custom comparison function that will be used to order the sort key values for this rule.

=back

Each of these functions may return a postive, zero, or negative value based on the relationship of the values in the $a and $b positions of the current @ValueSet array. An undefined return indicates that the comparator is unable to provide an ordering for this pair, in which case the choice will fall through to the next comparator in the list; if no comparator specifies an order, they are left in their original order.

=cut

# $three_way_cmp = _cmp_cmp;		
sub _cmp_cmp { 
  $ValueSet[$a] cmp $ValueSet[$b] 
}

# $three_way_cmp = _cmp_bytewise;		
sub _cmp_bytewise { 
  $ValueSet[$a] cmp $ValueSet[$b] 
}

# $three_way_cmp = _cmp_numeric;
sub _cmp_numeric { 
  $ValueSet[$a] <=> $ValueSet[$b] 
}

# $three_way_cmp = _cmp_empty_first;
sub _cmp_empty_first {
  # If neither is empty, we have no opinion.
  # If only one is empty, place it first
  # If they're both empty, they're equivalent
  (  ! length($ValueSet[$a]) ) 
    ? ( (  ! length($ValueSet[$b]) ) ? 0 :  -1 )
    : ( ( ! length($ValueSet[$b]) ) ? 1 : undef  );
}

# $three_way_cmp = _cmp_numbers_first;
sub _cmp_numbers_first {
  # Use an extra array to cache our converted value
  $Rule->{'ext_numeric'} ||= [];
  my $is_numeric = $Rule->{'ext_numeric'};

  # If we haven't already, check to see if the values are purely numeric
  defined $is_numeric->[$a] or 
	  $is_numeric->[$a] = ( $ValueSet[$a] =~ /\A\-?(?:\d*\.)?\d+\Z/ );
  defined $is_numeric->[$b] or 
	  $is_numeric->[$b] = ( $ValueSet[$b] =~ /\A\-?(?:\d*\.)?\d+\Z/ );
  
  # If they're both numeric, use numeric comparison, 
  # If one's numeric and the other isn't, put the number first
  # If neither is numeric, we have no opinion
  ( $is_numeric->[$a] ) 
    ? ( ( $is_numeric->[$b] ) ? ( $ValueSet[$a] <=> $ValueSet[$b] ) :  -1 )
    : ( ( $is_numeric->[$b] ) ? 1 :  undef );
}

# $three_way_cmp = _cmp_textual;
sub _cmp_textual {
  # Use an extra array to cache our converted value
  $Rule->{'ext_textual'} ||= [];
  my $mangled = $Rule->{'ext_textual'};
  
  # If we haven't already, generate a lower-case, alphanumeric-only value
  foreach my $idx ( $a, $b ) {
    next if defined $mangled->[$idx];
    local $_ = lc( $ValueSet[$idx] );     
    tr/0-9a-z/ /cs; 
    s/\A\s+//; 
    s/\s+\Z//; 
    $mangled->[$idx] = $_
  }
  
  # If both items have an alphanumeric value, compare them on that basis
  # If one is alphanumeric and the other is punctuation/empty, put alpha last.
  ( length($mangled->[$a]) ) 
    ? ( length($mangled->[$b]) ? ( $mangled->[$a] cmp $mangled->[$b] ) : -1 )
    : ( length($mangled->[$b]) ? 1 : undef );
}

# $three_way_cmp = _cmp_locale		
sub _cmp_locale { 
  require POSIX;
  POSIX::strcoll( $ValueSet[$a], $ValueSet[$b] );
}

# $three_way_cmp = _cmp_lc_locale
sub _cmp_lc_locale { 
  require POSIX;
  POSIX::strcoll( lc($ValueSet[$a]), lc($ValueSet[$b]) );
}

sub _cmp_make_compound {
  my @comparators = @_;
  sub {
    foreach my $comparator ( @comparators ) {
      # Call each comparison function in an attempt to establish an ordering
      my $rc = &$comparator;
      # If the comparator returns undef, it has no opinion; call the next one
      return($rc) if defined($rc);
    }
  }
}

{ 
  no strict 'refs';
  *{'_cmp_num_lc_locale'} = _cmp_make_compound( \&_cmp_empty_first, \&_cmp_numbers_first, \&_cmp_lc_locale );
}

# $three_way_cmp = _cmp_natural;
sub _cmp_natural {

  # If neither is empty, we have no opinion.
  # If only one is empty, place it first
  # If they're both empty, they're equivalent
  (  ! length($ValueSet[$a]) ) 
    ? ( (  ! length($ValueSet[$b]) ) ? return 0 :  return -1 )
    : ( ( ! length($ValueSet[$b]) ) ? return 1 : undef  );

  # Use an extra array to cache our converted value
  $Rule->{'ext_numeric'} ||= [];
  my $is_numeric = $Rule->{'ext_numeric'};

  # If we haven't already, check to see if the values are purely numeric
  defined $is_numeric->[$a] or 
	  $is_numeric->[$a] = ( $ValueSet[$a] =~ /\A\-?(?:\d*\.)?\d+\Z/ );
  defined $is_numeric->[$b] or 
	  $is_numeric->[$b] = ( $ValueSet[$b] =~ /\A(?:\d*\.)?\d+\Z/ );
  
  # If they're both numeric, use numeric comparison, 
  # If one's numeric and the other isn't, put the number first
  # If neither is numeric, we have no opinion
  ( $is_numeric->[$a] ) 
    ? return( ( $is_numeric->[$b] ) ? ( $ValueSet[$a] <=> $ValueSet[$b] ) : -1 )
    : ( ( $is_numeric->[$b] ) ? return 1 :  undef );
  
  # Use an extra array to cache our converted value
  $Rule->{'ext_textual'} ||= [];
  my $mangled = $Rule->{'ext_textual'};
  
  # If we haven't already, generate a lower-case, alphanumeric-only value
  foreach my $idx ( $a, $b ) {
    next if defined $mangled->[$idx];
    local $_ = lc( $ValueSet[$idx] );     
    tr/0-9a-z/ /cs; 
    s/\A\s+//; 
    s/\s+\Z//; 
    s/\A(the)\s(.*)/$2 $1/;
    $mangled->[$idx] = $_
  }
  
  # If both items have an alphanumeric value, compare them on that basis
  # If one is alphanumeric and the other is punctuation/empty, put alpha last.
  ( length($mangled->[$a]) ) 
    ? ( length($mangled->[$b]) ? ( $mangled->[$a] cmp $mangled->[$b] ) : -1 )
    : ( length($mangled->[$b]) ? 1 : undef );
}

########################################################################

=head2 Ascending or Descending Order

For the order option, you may specify one of the following I<option_value>s:

=over 4

=item forward I<or> ascending

The default order, from lower values to higher ones.

=item reverse I<or> descending

Reverses the ordering dictated by a sort rule.

=back


=head2 Sorting Engines

Depending on the specific sorting rules used in a given call, this module automatically selects an internal function that provides an appropriate approach to implementing the sort, called the sort "engine". 

You can override this selection by setting an "engine" option on the first sort key, which can either contain either the name of one of the engines, described below, or a CODEREF with equivalent behavior.

=over 4

=item trivial

In the common case of sorting raw values with a cmp comparison, the fast-but-simple "trivial" engine is used, which simply applies Perl's default sorting.

=item orcish

For a complex multi-key sort the "orcish" engine is typically selected.

=item precalc

Used when there's only one sorting key.

You may also set the $PreCalculate package variable to true to force this engine to be selected. Because the sort key values for the list are calculated before entering Perl's sort operation, there's less of a chance of possible re-entry problems due to nested uses of the sort operator, which causes a fatal error in at least some versions of Perl.

=item packed

Some sorts are handled with the Guttman-Rosler technique, extracting packed keys and using Perl's default sort function, which is substantially faster, but currently only a limited set of simple comparisons can be handled this way. (For more information on packed-default sorting, see http://www.sysarch.com/perl/sort_paper.html or search for "Guttman-Rosler".)

=back

=cut

sub _sorted_trivial {
  sort @Array
}

sub _sorted_precalc {
  foreach my $rule (@Rules) {
    $rule->{ext_value} = [ _extract_values_for_rule( $rule, @Array ) ]
  }
  return @Array[ sort _sorted_indexes_precalc 0 .. $#Array ];
}

# Compare indexes $a and $b acording to each of the specified rules
# $three_way_cmp = _sorted_indexes_precalc;		
sub _sorted_indexes_precalc { 
  # implicit: $a, $b
  
  RULE: foreach $Rule (@Rules) {
    local *ValueSet = ( $Rule->{ext_value} ||= [] );
    
    # If the function returns zero or undef, the values are equivalent
    my $rc = &{ $Rule->{compare_func} }
	or next RULE;
    
    # Else return the comparison results, reversing them first if necessary
    return $rc * $Rule->{order_sign};
  }
  # If the items are equivalent for all of the rules, don't change their order
  # warn "Comparing $a and $b: '$ValueSet[$a]' " . ('=') . " '$ValueSet[$b]'\n";
  return $a <=> $b;
}

sub _sorted_orcish {
  return @Array[ sort _sorted_indexes_orcish 0 .. $#Array ];
}

sub _sorted_indexes_orcish { 
  # implicit: $a, $b
  
  RULE: foreach $Rule (@Rules) {
    # If we haven't already, calculate the value of each item for this rule
    local *ValueSet = ( $Rule->{ext_value} ||= [] );
    defined $ValueSet[$a] or $ValueSet[$a] = _extract_value($Array[$a], $Rule);
    defined $ValueSet[$b] or $ValueSet[$b] = _extract_value($Array[$b], $Rule);
    
    # If the function returns zero or undef, the values are equivalent
    my $rc = &{ $Rule->{compare_func} }
	or next RULE;
    
    # Else return the comparison results, reversing them first if necessary
    return $rc * $Rule->{order_sign};
  }
  # If the items are equivalent for all of the rules, don't change their order
  # warn "Comparing $a and $b: '$ValueSet[$a]' " . ('=') . " '$ValueSet[$b]'\n";
  return $a <=> $b;
}

sub _sorted_packed {
  my @packed;
  if ( @Rules == 1 ) {
    @packed = map
    &{ $Rules[0]->{extract_func} }( $Array[$_], @{ $Rules[0]->{extract_args} } )
      . "\0" . $_, 
    ( 0 .. $#Array );
  } else {
    @packed = map { 
      my $item = $Array[$_]; 
      join( "\0", 
	map(&{ $_->{extract_func} }( $item, @{ $_->{extract_args} } ), @Rules),
	$_ 
      ) 
    } ( 0 .. $#Array );
  }
  
  # warn "Packed: " . join(', ', map "'$_'", @packed ) . "\n";
  
  return @Array[ map substr($_, 1 + rindex $_, "\0"), sort @packed ];
}

########################################################################

=head1 STATUS AND SUPPORT

This release of Data::Sorting is intended for public review and feedback. 

  Name            DSLIP  Description
  --------------  -----  ---------------------------------------------
  Data::
  ::Sorting       bdpfp  Multi-key sort using function results

Further information and support for this module is available at www.evoscript.org.

Please report bugs or other problems to E<lt>bugs@evoscript.comE<gt>.

=head1 BUGS AND TO DO

The following issues have been noted for future improvements:

Convert more types of comparisons to packed-default sorts for speed.

Further investigate the current status of the Sort::Records module.

Add a comparator function for an alpha-numeric-spans sorting model
like Sort::Naturally.

Interface to Sort::PolySort for alternate comparator styles, like
"name" and "usdate".

For non-scalar values, compare referents along the lines of
Ref::cmpref().

Provide better handling for nested sorts; perhaps throw an exception
from the inner instance to the outer, catch and set $PreCalculate,
then go back into the loop?

Replace dynamic scoping with object instances for thread safety.
May not be necessary given changes in threading models.

=head1 CREDITS AND COPYRIGHT

=head2 Developed By

  M. Simon Cavalletto, simonm@cavalletto.org
  Evolution Softworks, www.evoscript.org

=head2 Copyright

Copyright 2003 Matthew Cavalletto. 

Portions copyright 1996, 1997, 1998, 1999 Evolution Online Systems, Inc. 

=head2 License

You may use, modify, and distribute this software under the same terms as Perl.

=cut

########################################################################

1;
