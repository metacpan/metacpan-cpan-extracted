##======================================================================
## Authors:
##    Martial.Chateauvieux@sfs.siemens.de
##    O.Capdevielle@cadextan.fr
##======================================================================
## Copyright (c) 2001, Siemens Financial Services. All rights reserved.
## This library is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##======================================================================
## $Log:$
##======================================================================

package Data::Reconciliation::Rule;

require 5.005_62;
use strict;
use warnings;

use Carp;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $src1 = shift;
    my $src2 = shift;

    croak "Usage: new $class (<Data::Table>, <Data::Table>)"
	if ! eval { $src1->isa('Data::Table') } ||
	    ! eval { $src2->isa('Data::Table') };

    return bless {
	'srcs' => [$src1, $src2]
    }, $class;
}

sub identification {
    my $this = shift;

    if (@_ > 0) {
	my $field_names_1 = shift;
	my $canon_sub_1   = shift;
	my $field_names_2 = shift;
	my $canon_sub_2   = shift;

	foreach (@$field_names_1) {
	    croak "identification: Inavlid column name [$_]"
		if $this->{'srcs'}->[0]->colIndex($_) == -1;
	}
	foreach (@$field_names_2) {
	    croak "identification: Inavlid column name [$_]"
		if $this->{'srcs'}->[1]->colIndex($_) == -1;
	}
	
	my @field_idx_1   = map {$this->{'srcs'}->[0]->colIndex($_)} @$field_names_1;
	my @field_idx_2   = map {$this->{'srcs'}->[1]->colIndex($_)} @$field_names_2;
	
	$canon_sub_1 = sub { join '|', @_ }
	if ! defined $canon_sub_1;
	$canon_sub_2 = sub { join '|', @_ }
	if ! defined $canon_sub_2;
	
	croak 'Usage: $rule->identification(\@fields_1, \&canon_sub_1, ' .
	    '\@fields_2, \&canon_sub_2);'
		if ! (('ARRAY' eq ref $field_names_1) && 
		      ('CODE' eq ref $canon_sub_1) &&
		      ('ARRAY' eq ref $field_names_2) && 
		      ('CODE' eq ref $canon_sub_2));
	
	$this->{'field_names'}->[0] = [ @$field_names_1];
	$this->{'fields'}->[0]      = [ @field_idx_1];
	$this->{'canon_sub'}->[0]   = $canon_sub_1;
	$this->{'field_names'}->[1] = [ @$field_names_2];
	$this->{'fields'}->[1]      = [ @field_idx_2];
	$this->{'canon_sub'}->[1]   = $canon_sub_2;
    }

    return ($this->{'fields'}->[0],
	    $this->{'canon_sub'}->[0],
	    $this->{'fields'}->[1],
	    $this->{'canon_sub'}->[1]);
}

sub isNumber ($) { 
    return undef if ! defined $_[0];
    shift =~ /^\s*([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?\s*$/;
}

sub trim ($) {
    return undef if ! defined $_[0];
    my $field = shift;
    $field =~ s/\s+$//o;
    $field =~ s/^\s+//o;
    return $field;
}

sub add_comparison {
    my $this             = shift;
    my $field_names_1    = shift;
    my $canon_sub_1      = shift;
    my $field_names_2    = shift;
    my $canon_sub_2      = shift;
    my $compare_sub      = shift;
    my $compare_sub_name = shift;
    my $constants        = shift;
    
    croak('usage: $r->add_comparison(',
	  '\@field_names_1, \&canon_1, ',
	  '\@field_names_2, \&canon_2, ',
	  '\&compare, $compare_name, \@constants); ')
	if ! (('ARRAY' eq ref $field_names_1) && 
	      ('ARRAY' eq ref $field_names_2) && 
	      ((! defined $canon_sub_1) || ('CODE' eq ref $canon_sub_1)) && 
	      ((! defined $canon_sub_2) || ('CODE' eq ref $canon_sub_2)) && 
	      ((! defined $compare_sub) || ('CODE' eq ref $compare_sub)) &&
	      ((! defined $constants) || ('ARRAY' eq ref $constants)));

    foreach (@$field_names_1) {
	croak "add_comparison: Inavlid column name [$_]"
	    if $this->{'srcs'}->[0]->colIndex($_) == -1;
    }
    foreach (@$field_names_2) {
	croak "add_comparison: Inavlid column name [$_]"
	    if $this->{'srcs'}->[1]->colIndex($_) == -1;
    }

    my @field_idx_1 = map {$this->{'srcs'}->[0]->colIndex($_)} @$field_names_1;
    my @field_idx_2 = map {$this->{'srcs'}->[1]->colIndex($_)} @$field_names_2;

    if (! defined $compare_sub) {

	my $sub_1 = defined $canon_sub_1 ? $canon_sub_1 : sub { @_ };
	my $sub_2 = defined $canon_sub_2 ? $canon_sub_2 : sub { @_ };

	$compare_sub = sub (\@\@\@\@$) {
	    my $field_names_1  = shift;
	    my $field_values_1 = shift;
	    my $field_names_2  = shift;
	    my $field_values_2 = shift;
	    my $constants      = shift;
	    my $func_name      = shift;
	    
	    my $value_1 = join '|', @$field_values_1;
   	    my $value_2 = join '|', @$field_values_2;

	    if (isNumber($value_1) ?
		$value_1 <=> $value_2 :
		trim($value_1) cmp trim($value_2)) {
		return sprintf("SRC1.%s=[%s] <> SRC2.%s=[%s]",
			       join('.', @$field_names_1),
			       $value_1,
			       join('.', @$field_names_2),
			       $value_2);
	    } else { 
		return undef ;
	    }
	};
    }

    push @{$this->{'comparison'}}, [$field_names_1, \@field_idx_1, $canon_sub_1, 
				    $field_names_2, \@field_idx_2, $canon_sub_2,
				    $compare_sub, $compare_sub_name, $constants];
}

sub signature {
    my $this      = shift;
    my $source_nb = shift;
    my $record    = shift;

    my $fields = $this->{'fields'}->[$source_nb];
    my $canon = $this->{'canon_sub'}->[$source_nb];

    return &$canon(@{$record}[@$fields]);
}

sub compare {
    my $this = shift;
    my $record_1 = shift; #array ref
    my $record_2 = shift; #array ref

    my @messages;

    foreach my $comp (@{$this->{'comparison'}}) {
	my($fnames1, $fidx1, $sub_1, 
	   $fnames2, $fidx2, $sub_2, 
	   $comp_sub, $comp_sub_name, $consts) = @$comp;
	my $msg = &$comp_sub($fnames1,
			     [ defined $sub_1 ? 
			       &$sub_1(@{$record_1}[@$fidx1]) : 
			       @{$record_1}[@$fidx1] ],
			     $fnames2,
			     [ defined $sub_2 ? 
			       &$sub_2(@{$record_2}[@$fidx2]) : 
			       @{$record_2}[@$fidx2] ],
			     $consts,
			     $comp_sub_name);
	push @messages, $msg if defined $msg;
    }

    return @messages;
}

1;
__END__

=head1 NAME

Data::Reconciliation::Rule - Perl extension data reconciliation

=head1 SYNOPSIS

   use Data::Reconciliation::Rule;

   my $r = new Data::Reconciliation::Rule(<Data::Table>, <Data::Table>);

   $r->identification(\@field_names_1,
		      \&canonical_1,
		      \@field_names_2,
		      \&canonical_2);

   $r->add_comparison(\@field_names_1,
		      \&canon_sub_1,
		      \@fields_names_2,
		      \&canon_sub_2,
		      \&compare_sub,
                      $compare_sub_name,
		      \@constants);

   my $sigur = $r->signature($src_nb,  # {0, 1}
			     \@record);

   my @msgs  = $r->compare(\@record_1, 
			   \@record2);


=head1 DESCRIPTION

This package implements the rule class used by the
C<Data::Reconciliation> algorithm.

A C<Data::Reconciliation::Rule> is composed of two parts, the
identification part and the comparison part.

=head1 CONSTRUCTOR

=over 

=item C<new>

The constructor takes needs the two sources to be reconciliated as
parameters. The sources must be of type C<Data::Table>. (The sources
are needed for the conversion of column names into column indices, and
to check that the column names (resp. indices) passed to the methods
actually exist).

=back

=head1 METHODS

=over 

=item C<identification>

The identification part provides a the mean for the Reconciliation
algorithm to build a signature for the records in the two sources to
be reconciliated. For each source, a list of column names must be
provided and an optional function to build a canonical form of the
signature (This function will typically change the value to uppercase,
suppress non-alphanumeric characters, etc...). if not defined the
function defaults to C<sub { join '|', @_ }>

=item C<add_comparison>

The comparison part provides the mean for the Reconciliation
algorithms to compare records and report differences. For one rule,
multiple comparisons can be specified (one per column for example).

for each data source, the list of columns names to be used in the
comparison must be specified. An optional subroutine to rework the
field values can be specified. An optional compare function can be
specified. The default compare sub function is:

	sub (\@\@\@\@;\@$) {
	    my $field_names_1  = shift;
	    my $field_values_1 = shift;
	    my $field_names_2  = shift;
	    my $field_values_2 = shift;
	    #my $constants     = shift;
	    #my $func_name     = shift;
	    
	    my $value_1 = join '|', @$field_values_1;
   	    my $value_2 = join '|', @$field_values_2;

	    if (isNumber($value_1) ?
		$value_1 <=> $value_2 :
		trim($value_1) cmp trim($value_2)) {
		return sprintf("SRC1.%s=[%s] <> SRC2.%s=[%s]",
			       join('.', @$field_names_1),
			       $value_1,
			       join('.', @$field_names_2),
			       $value_2);
	    } else { 
		return undef ;
	    }
	}

=item C<signature>

The signature method is called by the C<Data::Reconciliation>
algorithm to compute values which are used to identify records to be
compared in the two sources. It uses the values passed to the
identification method.

=item C<compare>

The compare method is called by the C<Data::Reconciliation> algorithm
to compare the records identified by using the signature method. It
uses the values passed to the add_comparison method.

=back

=head2 EXPORT

None.

=head1 AUTHORS

Martial.Chateauvieux@sfs.siemens.de, 
O.Capdevielle@cadextan.fr

=head1 SEE ALSO

L<Data::Reconciliation>, L<Data::Table>

=cut
