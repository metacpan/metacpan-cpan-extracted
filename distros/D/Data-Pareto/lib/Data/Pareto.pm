package Data::Pareto;

use warnings;
use strict;

use Scalar::Util qw( reftype );
use Carp;

=head1 NAME

Data::Pareto - Computing Pareto sets in Perl

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use Data::Pareto;
  
  # only first and third columns are used in comparison
  # the others are simply descriptive
  my $set = new Data::Pareto( { columns => [0, 2] } );
  $set->add(
      [ 5, "pareto", 10, 11 ],
      [ 5, "dominated", 11, 9 ],
      [ 4, "pareto2", 12, 12 ] 
  );

  # this returns [ [ 5, "pareto", 10, 11 ], [ 4, "pareto2", 12, 12 ] ],
  # the other one is dominated on selected columns
  $set->get_pareto_ref;

=head1 DESCRIPTION

This module makes calculation of Pareto set. Given a set of vectors
(i.e. arrays of simple scalars), Pareto set is all the vectors from the given
set which are not dominated by any other vector of the set. A vector C<X> is
said to be dominated by C<Y>, iff C<< X[i] >= Y[i] >> for all C<i> and
C<< X[i] > Y[i] >> for at least one C<i>.

Pareto sets play an important role in multiobjective optimization, where
each non-dominated (i.e. Pareto) vector describes objectives value of
"optimal" solution to the given problem.

This module allows occurrence of duplicates in the set - this makes it
rather a bag than a set, but is useful in practice (e.g. when we want to
preserve two solutions giving the same objectives value, but structurally
different). This assumption influences dominance definition given above:
two duplicates never dominate each other and hence can be present in the Pareto
set. This is controlled by C<duplicates> option passed to L<new()|/new>: if set
to C<true> value, duplicates are allowed in Pareto set; otherwise, only the
first found element of the subset of duplicated vectors is preserved in Pareto
set.

The values are allowed to be invalid. The meaning of 'invalid' is 'the worst
possible'. It's different concept than 'unknown'; unknown value make the
definition of domination less clear.

By default, the comparison of column values is numerical and the smaller
value dominates the larger one. If you want to override this behaviour, pass
your own dominator sub in arguments to L<new()|/new>.

=head1 FUNCTIONS

By default, a vector is passed around as a ref to array of consecutive column
values. This means you shouldn't mess with it after passing to C<add> method.

=cut


=head2 new

Creates a new object for calculating Pareto set.

The first argument passed is a hashref with options; the recognized options are:

=over

=item * C<columns>

Arrayref containing column numbers which should be used for determining
domination and duplication. Column numbers are C<0>-based array indexes to
data vectors.

Only values at those positions will be ever compared between vectors.
Any other data in the vectors may be present and is not used in any way.

At least one column number should be passed, for obvious reasons.

=item * C<duplicates>

If set to C<true> value, duplicated vectors are all put in Pareto set (if they
are Pareto, of course). If set to C<false>, duplicates of vectors already
in the Pareto set are discarded.

=item * C<invalid>

The value considered invalid in pareto set. Such value is dominated by
any value and dominates only invalid value.

However, computations of domination in presence of invalid values can be
considerably slower, as much as 5 times. So it probably will be faster to first
parse the data and replace invalid markers with some huge-and-surely-dominated
values.

=item * C<column_dominator>

The sub(s) used to compare specific column values and determining domination
between them. Scalar, sub ref or hash ref. If not set, the default is that
the numerically smaller value dominates the other one.

When the scalar is passed, it is assumed to be the name of a predefined
dominator. This is a much faster option to specifying the sub of your own.
Recognized dominators are:

=over

=item * C<min> numerically smaller value dominates

=item * C<max> numerically greater value dominates

=item * C<lexi> earlier in collation order value dominates (lexicographical
order) 

=item * C<lexi_rev> later in collation order value dominates (reversed
lexicographical order) 

=item * C<std> standard, i.e. C<min> dominator

=back

During creation of Pareto set, the dominator sub is called with three arguments:
column number, first vector's value, second vector's value, and should return
C<true>, when the second value dominates the first one, assuming they appeared
in the specified column.

Make sure that your sub returns C<true> when two passed values are the same. 
This is necessary to obey the whole Pareto set domination contract.
 
There are two approaches possible when the values in different columns are of
different types, in the sense of domination. First, you can use passed column
number to decide the domination check function. Alternatively, you can pass a
hash ref with mapping from the column number to the sub ref used to compare the
given column:

  my $lexi_dominator = sub {
      my ($col, $dominated, $by) = @_;
      return ($dominated ge $by);
  };
  my $min_dominator = sub {
      my ($col, $dominated, $by) = @_;
      return ($dominated >= $by);
  }
  
  my $set = new Data::Pareto({
  	  columns => [0, 2],
  	  column_dominator => {
  	  	  0 => $lexi_dominator,
  	  	  2 => $min_dominator
  	  }
  });
  $set->add(['a', 'label 1', 12], ['b', 'label 2', 9]);

=back

The rest of arguments are assumed to be vectors, and passed to L<add()|/add>
method.

=cut


sub new {
	my ($class, $attrs) = (shift, shift);
	my $self = bless {
		pareto => [ ],
		vectorStatus => { },
		%$attrs
	}, $class;
	$self->_construct_subs;
	
	$self->add(@_) if @_;
	return $self;
}

=head2 add

Tests vectors passed as arguments and adds the non-dominated ones to the
Pareto set.

=cut

sub add {	
	my $self = shift;
	$self->_update_pareto($_) for @_;
}

=head2 get_pareto

Returns the current content of Pareto set as a list of vectors.

=cut

sub get_pareto {
	my ($self) = @_;
	return (@{$self->{pareto}});
}

=head2 get_pareto_ref

Returns the current content of Pareto set as a ref to array with vectors.
The return value references the original array, so treat it as read-only! 

=cut

sub get_pareto_ref {
	my ($self) = @_;
	return $self->{pareto};	
}

# update (potentially) the set with a new vector:
# check if it is Pareto, if so, remove dominated vectors 
sub _update_pareto {
	my ($self, $NV) = @_;
	
	# check if we already have a duplicate?
	# if so, handle it gently, so there are no mind-cracking
	# algorithm variations after that
	
	if ($self->_has_duplicates($NV)) {
		# ...then it depends on the policy
		if ($self->{duplicates}) {
			# add the duplicated vector to the pareto set
			push @{$self->{pareto}}, $NV;
		} else {
			# simply disgard the new vector
		}
		return;
	}
	
	my @newP = ( );
	my $surePareto = 0;
	
	# check with every vector considered pareto so far
	for my $o (@{$self->{pareto}}) {
		if ($surePareto) {
			# preserve the current vector only if it is not dominated by new (now Pareto) vector
			if ($self->{_sub_is_dominated}($self, $o, $NV)) {
				$self->_ban_vector($o);
			} else {
				push @newP, $o;
			}
		} else {
			# stop processing with unchanged Pareto set if the new vector is dominated by the current one
			return if $self->{_sub_is_dominated}($self, $NV, $o);
			
			# mark new vector as "sure Pareto" only if it dominates the current vector
			if ($self->{_sub_is_dominated}($self, $o, $NV)) {
				$surePareto = 1;
				# ...and hence we don't preserve the dominated current vector
				$self->_ban_vector($o);
				next;
			}
			
			# otherwise, the current vector is for sure Pareto still, so preserve it
			push @newP, $o;
		}
	}

	push @newP, $NV;
	$self->_mark_vector($NV);
	$self->{pareto} = \@newP;
}

=head2 is_dominated

Checks if the first vector passed is dominated by the second one.
The comparison is made based on the values in vectors' columns, which
were passed to L<new()|/new>.

The vectors passed are never duplicates of each other when this method is
called from inside this module.

Returns C<true>, when the first vector from arguments list
is dominated by the other one, and C<false> otherwise.

=cut

sub is_dominated { $_[0]->{_sub_is_dominated}(@_); }	# pass the whole @_, as the sub thinks it is a method

# these are is_dominated() parts which will be composed into the function,
# depending on the constructor options.
my %_is_dominated_parts = (
	invalid => <<'_EOT_',
			next if $self->{_sub_is_invalid}($dominated->[$col]);	# invalid dominated by anything
			return 0 if $self->{_sub_is_invalid}($by->[$col]);	# invalid can't dominate valid
_EOT_
	dominator_min => '($dominated->[$col] >= $by->[$col])',
	dominator_max => '($dominated->[$col] <= $by->[$col])',
	dominator_lexi => '($dominated->[$col] ge $by->[$col])',
	dominator_lexi_rev => '($dominated->[$col] le $by->[$col])',
	
	_dominator_custom => <<'_EOT_',
			$self->{column_dominator}($col, $dominated->[$col], $by->[$col])
_EOT_
	_dominator_custom_hash => <<'_EOT_',
			$self->{column_dominator}{$col}($col, $dominated->[$col], $by->[$col])
_EOT_

);
$_is_dominated_parts{dominator_std} = $_is_dominated_parts{dominator_min};
 
sub _construct_subs {
	my ($self) = @_;
	
	my $invalid_part;
	if (exists $self->{invalid}) {
		my $inv = $self->{invalid};
		$self->{_sub_is_invalid} = sub { $_[0] eq $inv };
		$invalid_part = $_is_dominated_parts{invalid};
	} else {
		$self->{_sub_is_invalid} = sub { 0 };
		$invalid_part = '';
	}
	
	my $cmp_part;
	if (exists $self->{column_dominator}) {
		my $dom = $self->{column_dominator} || '';
		my $type = reftype $dom;
		if (!defined $type) {
			# builtin
			$cmp_part = $_is_dominated_parts{"dominator_$dom"};
			croak "Unrecognized dominator builtin '$dom'" unless $cmp_part;
		} elsif ($type && $type eq 'HASH') {
			$cmp_part = $_is_dominated_parts{_dominator_custom_hash};
		} else {
			$cmp_part = $_is_dominated_parts{_dominator_custom};
		}
	} else {
		$cmp_part = $_is_dominated_parts{dominator_std};
	}
	
	my $sub_str = <<'_EOT_'
		sub {
			my ($self, $dominated, $by) = @_;
			for my $col (@{$self->{columns}}) {
_EOT_
. <<_EOT_
				$invalid_part
				return 0 unless $cmp_part;
			}
			1;
		}
_EOT_
;
	$self->{_sub_is_dominated} = eval $sub_str;
}

=head2 is_invalid

Checks if the given value is considered invalid for the current object.
Every value is valid by default.

=cut

sub is_invalid { return $_[0]->{_sub_is_invalid}($_[1]); }

# calculate the string repr. of a vector; to be used as a hash key
sub _vector_key {
	my ($self, $v) = @_;
	my @cols = ( );
	for my $c (@{$self->{columns}}) {
		push @cols, $v->[$c];
	}
	
	return join ';', @cols;
}

# checks if the given vector has duplicates in Pareto
sub _has_duplicates {
	my ($self, $v) = @_;
	my $key = $self->_vector_key($v);
	return (exists $self->{vectorStatus}{$key} && $self->{vectorStatus}{$key} > 0);
}

# mark the vector as not present in Pareto.
# In the future it can be used to ban the vector from trying to return
# to the Pareto set.
sub _ban_vector {
	my ($self, $v) = @_;
	my $key = $self->_vector_key($v);
	$self->{vectorStatus}{$key} = 0;
}

# mark vector as present in the Pareto set.
sub _mark_vector {
	my ($self, $v) = @_;
	my $key = $self->_vector_key($v);
	$self->{vectorStatus}{$key} = 1;
}

=head1 TODO

Allow specifying built-in dominators inside dominator hash.

For large data sets calculations become time-intensive. There are a couple
of techniques which might be applied to improve the performance:

=over

=item * defer the phase of removing vectors dominated by newly added vectors
to L<get_pareto()|/get_pareto> call; this results in smaller number of arrays
rewritings.

=item * split the set of vectors being added into smaller subsets, calculate
Pareto sets for such subsets, and then apply insertion of resulting Pareto
subsets to the main set; this results in smaller number of useless tries of
adding dominated vectors into the set.

=back

=head1 AUTHOR

Przemyslaw Wesolek, C<< <jest at go.art.pl> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-pareto at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Pareto>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Pareto


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Pareto>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Pareto>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Pareto>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Pareto>

=back

=head1 COPYRIGHT & LICENSE


Copyright 2009 Przemyslaw Wesolek

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0. For details, see the full
text of the license in the file LICENSE.

=cut

1; # End of Data::Pareto
