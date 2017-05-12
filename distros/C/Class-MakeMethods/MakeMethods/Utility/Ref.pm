=head1 NAME

Class::MakeMethods::Utility::Ref - Deep copying and comparison 

=head1 SYNOPSIS

  use Class::MakeMethods::Utility::Ref qw( ref_clone ref_compare );
  
  $deep_copy = ref_clone( $original );
  $positive_zero_or_negative = ref_compare( $item_a, $item_b );

=head1 DESCRIPTION

This module provides utility functions to copy and compare arbitrary references, including full traversal of nested data structures.

=cut

########################################################################

package Class::MakeMethods::Utility::Ref;

$VERSION = 1.000;

@EXPORT_OK = qw( ref_clone ref_compare );
sub import { require Exporter and goto &Exporter::import } # lazy Exporter

use strict;

######################################################################

=head2 REFERENCE

The following functions are provided:

=head2 ref_clone()

Make a recursive copy of a reference.

=cut

use vars qw( %CopiedItems );

# $deep_copy = ref_clone( $value_or_ref );
sub ref_clone {
  local %CopiedItems = ();
  _clone( @_ );
}

# $copy = _clone( $value_or_ref );
sub _clone {
  my $source = shift;
  
  my $ref_type = ref $source;
  return $source if (! $ref_type);
  
  return $CopiedItems{ $source } if ( exists $CopiedItems{ $source } );
  
  my $class_name;
  if ( "$source" =~ /^\Q$ref_type\E\=([A-Z]+)\(0x[0-9a-f]+\)$/ ) {
    $class_name = $ref_type;
    $ref_type = $1;
  }
  
  my $copy;
  if ($ref_type eq 'SCALAR') {
    $copy = \( $$source );
  } elsif ($ref_type eq 'REF') {
    $copy = \( _clone ($$source) );
  } elsif ($ref_type eq 'HASH') {
    $copy = { map { _clone ($_) } %$source };
  } elsif ($ref_type eq 'ARRAY') {
    $copy = [ map { _clone ($_) } @$source ];
  } else {
    $copy = $source;
  }
  
  bless $copy, $class_name if $class_name;
  
  $CopiedItems{ $source } = $copy;
  
  return $copy;
}

######################################################################

=head2 ref_compare()

Attempt to recursively compare two references.

If they are not the same, try to be consistent about returning a
positive or negative number so that it can be used for sorting.
The sort order is kinda arbitrary.

=cut

use vars qw( %ComparedItems );

# $positive_zero_or_negative = ref_compare( $A, $B );
sub ref_compare {
  local %ComparedItems = ();
  _compare( @_ );
}

# $positive_zero_or_negative = _compare( $A, $B );
sub _compare { 
  my($A, $B, $ignore_class) = @_;

  # If they're both simple scalars, use string comparison
  return $A cmp $B unless ( ref($A) or ref($B) );
  
  # If either one's not a reference, put that one first
  return 1 unless ( ref($A) );
  return - 1 unless ( ref($B) );
  
  # Check to see if we've got two references to the same structure
  return 0 if ("$A" eq "$B");
  
  # If we've already seen these items repeatedly, we may be running in circles
  return undef if ($ComparedItems{ $A } ++ > 2 and $ComparedItems{ $B } ++ > 2);
  
  # Check the ref values, which may be data types or class names
  my $ref_A = ref($A);
  my $ref_B = ref($B);
  return $ref_A cmp $ref_B if ( ! $ignore_class and $ref_A ne $ref_B );
  
  # Extract underlying data types
  my $type_A = ("$A" =~ /^\Q$ref_A\E\=([A-Z]+)\(0x[0-9a-f]+\)$/) ? $1 : $ref_A;
  my $type_B = ("$B" =~ /^\Q$ref_B\E\=([A-Z]+)\(0x[0-9a-f]+\)$/) ? $1 : $ref_B;
  return $type_A cmp $type_B if ( $type_A ne $type_B );
  
  if ($type_A eq 'HASH') {  
    my @kA = sort keys %$A;
    my @kB = sort keys %$B;
    return ( $#kA <=> $#kB ) if ( $#kA != $#kB );
    foreach ( 0 .. $#kA ) {
      return ( _compare($kA[$_], $kB[$_]) or 
		_compare($A->{$kA[$_]}, $B->{$kB[$_]}) or next );
    }
    return 0;
  } elsif ($type_A eq 'ARRAY') {
    return ( $#$A <=> $#$B ) if ( $#$A != $#$B );
    foreach ( 0 .. $#$A ) {
      return ( _compare($A->[$_], $B->[$_]) or next );
    }
    return 0;
  } elsif ($type_A eq 'SCALAR' or $type_A eq 'REF') {
    return _compare($$A, $$B);
  } else {
    return ("$A" cmp "$B")
  }
}

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Ref> for the original version of the clone and compare functions used above.

See L<Clone> (v0.09 on CPAN as of 2000-09-21) for a clone method with an XS implementation.

The Perl6 RFP #67 proposes including clone functionality in the core.

See L<Data::Compare> (v0.01 on CPAN as of 1999-04-24) for a Compare method which checks two references for similarity, but it does not provide positive/negative values for ordering purposes.

=cut

######################################################################

1;
