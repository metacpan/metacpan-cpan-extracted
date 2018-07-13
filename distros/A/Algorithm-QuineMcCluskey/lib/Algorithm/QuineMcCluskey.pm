package Algorithm::QuineMcCluskey;

use strict;
use warnings;
use 5.010001;

use Moose;
use namespace::autoclean;

use Carp qw(croak);

use Algorithm::QuineMcCluskey::Util qw(:all);
use List::MoreUtils qw(uniq);
use List::Compare::Functional qw(get_complement get_intersection is_LequivalentR);
use Tie::Cycle;

#
# Vaguely consistent Smart-Comment rules:
# 3 pound signs for the code in BUILD() and generate_*() functions.
#
# 4 pound signs for code that manipulates prime/essentials/covers hashes:
#      row_dominance().
#
# 5 pound signs for the solve() and recurse_solve() code, and the remels() calls.
#
# The ::Format package is only needed for Smart Comments -- comment or uncomment
# in concert with Smart::Comments as needed.
#
#use Algorithm::QuineMcCluskey::Format qw(arrayarray hasharray chart);
#use Smart::Comments ('###');

#
# Required attributes to create the object.
#
# 1. 'width' is absolutely required (handled via Moose).
#
# 2. If 'columnstring' is provided, 'minterms', 'maxterms', and
#    'dontcares' can't be used.
#
# 3. Either 'minterms' or 'maxterms' is used, but not both.
#
# 4. 'dontcares' are used with either 'minterms' or 'maxterms', but
#    cannot be used by itself.
#
has 'width'	=> (
	isa => 'Int', is => 'ro', required => 1
);

has 'minterms'	=> (
	isa => 'ArrayRef[Int]', is => 'rw', required => 0,
	predicate => 'has_minterms'
);
has 'maxterms'	=> (
	isa => 'ArrayRef[Int]', is => 'rw', required => 0,
	predicate => 'has_maxterms'
);
has 'dontcares'	=> (
	isa => 'ArrayRef[Int]', is => 'rw', required => 0,
	predicate => 'has_dontcares'
);
has 'columnstring'	=> (
	isa => 'Str', is => 'ro', required => 0,
	predicate => 'has_columnstring',
	lazy => 1,
	builder => 'to_columnstring'
);

#
# Optional attributes.
#
has 'title'	=> (
	isa => 'Str', is => 'rw', required => 0,
	predicate => 'has_title'
);
has 'dc'	=> (
	isa => 'Str', is => 'rw',
	default => '-'
);
has 'vars'	=> (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	default => sub{['A' .. 'Z']}
);

#
# Change behavior.
#
has 'order_by' => (
	isa => 'Str', is => 'rw',
	default => 'none',
);

has 'minonly' => (
	isa => 'Bool', is => 'rw',
	default => 1
);

#
# The '_bits' fields are the terms' bitstring fields, and are
# internal attributes. No setting them at object creation.
#
has 'dc_bits'	=> (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	init_arg => undef,
	predicate => 'has_dc_bits'
);
has 'min_bits'	=> (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	init_arg => undef,
	predicate => 'has_min_bits'
);
has 'max_bits'	=> (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	init_arg => undef,
	predicate => 'has_max_bits'
);

#
# Prime implicants, essentials, and covers (the building blocks
# to, and final form of, the solution to the equation) are all "lazy"
# attributes and calculated when asked for in code or by the user.
#

#
# The calculated prime implicants.
#
has 'primes'	=> (
	isa => 'HashRef', is => 'ro', required => 0,
	init_arg => undef,
	reader => 'get_primes',
	writer => '_set_primes',
	predicate => 'has_primes',
	clearer => 'clear_primes',
	lazy => 1,
	builder => 'generate_primes'
);

#
# The essential prime implicants (not actually
# used in the algorithm, we keep track of what's
# essential in a list local to the recursive
# solving function).
#
has 'essentials'	=> (
	isa => 'ArrayRef', is => 'ro', required => 0,
	init_arg => undef,
	reader => 'get_essentials',
	writer => '_set_essentials',
	predicate => 'has_essentials',
	clearer => 'clear_essentials',
	lazy => 1,
	builder => 'generate_essentials'
);

#
# The terms that cover the primes needed to solve the
# truth table.
#
has 'covers'	=> (
	isa => 'ArrayRef[ArrayRef[Str]]', is => 'ro', required => 0,
	init_arg => undef,
	reader => 'get_covers',
	writer => '_set_covers',
	predicate => 'has_covers',
	clearer => 'clear_covers',
	lazy => 1,
	builder => 'generate_covers'
);

our $VERSION = 0.18;

sub BUILD
{
	my $self = shift;
	my $w = $self->width;
	my $last_idx = (1 << $w) - 1;
	my @terms;

	#
	# Catch errors involving minterms, maxterms, and don't-cares.
	#
	croak "Mixing minterms and maxterms not allowed"
		if ($self->has_minterms and $self->has_maxterms);

	if ($self->has_columnstring)
	{
		croak "No other terms necessary when using the columnstring attribute"
			if ($self->has_minterms or $self->has_maxterms or $self->has_dontcares);

		my $cl = $last_idx + 1 - length $self->columnstring;

		croak "Columnstring length is too short by ", $cl if ($cl > 0);
		croak "Columnstring length is too long by ", -$cl if ($cl < 0);
	}
	else
	{
		if ($self->has_minterms)
		{
			@terms = @{$self->minterms};
		}
		elsif ($self->has_maxterms)
		{
			@terms = @{$self->maxterms};
		}
		else
		{
			croak "Must supply either minterms or maxterms";
		}

		if ($self->has_dontcares)
		{
			my @intersect = get_intersection([$self->dontcares, \@terms]);
			if (scalar @intersect != 0)
			{
				croak "Term(s) ", join(", ", @intersect),
					" are in both the don't-care list and the term list.";
			}

			push @terms, @{$self->dontcares};
		}

		#
		# Can those terms be expressed in 'width' bits?
		#
		my @outside = grep {$_ > $last_idx or $_ < 0} @terms;

		if (scalar @outside)
		{
			croak "Terms (" . join(", ", @outside) . ") are larger than $w bits";
		}
	}

	#
	# Do we really need to check if they've set the
	# don't-care character to '0' or '1'? Oh well...
	#
	croak "Don't-care must be a single character" if (length $self->dc != 1);
	croak "The don't-care character can not be '0' or '1'" if ($self->dc =~ qr([01]));

	#
	# Make sure we have enough variable names, and limit them to the width.
	#
	croak "Not enough variable names for your width" if (scalar @{$self->vars} < $w);
	$self->vars([ @{$self->vars}[0 .. $w-1] ]);

	#
	# We've gotten past the error-checking. Create the object.
	#
	if ($self->has_columnstring)
	{
		my($min_ref, $max_ref, $dc_ref) = $self->break_columnstring();

		### min_ref: $min_ref
		### max_ref: $max_ref
		### don't cares: $dc_ref

		$self->minterms($min_ref) if (scalar @{$min_ref} );
		$self->dontcares($dc_ref) if (scalar @{$dc_ref} );
	}

	if ($self->has_minterms)
	{
		@terms = sort(uniq(@{$self->minterms}));

		my @bitstrings = map {
			substr(unpack("B32", pack("N", $_)), -$w)
		} @terms;

		$self->min_bits(\@bitstrings);
		### Min terms binary: $self->min_bits()
	}
	if ($self->has_maxterms)
	{
		@terms = sort(uniq(@{$self->maxterms}));

		my @bitstrings = map {
			substr(unpack("B32", pack("N", $_)), -$w)
		} @terms;

		$self->max_bits(\@bitstrings);
		### Max terms binary: $self->max_bits()
	}

	if ($self->has_dontcares)
	{
		my @dontcares = sort(uniq(@{$self->dontcares}));

		my @bitstrings = map {
			substr(unpack("B32", pack("N", $_)), -$w)
		} @dontcares;

		$self->dc_bits(\@bitstrings);
		### Don't-cares binary: $self->dc_bits()
	}

	$self->title("$w-variable truth table") unless ($self->has_title);

	return $self;
}

#
# Return a string made up of the function column. Position 0 in the string is
# the 0th row of the column, and so on.
#
sub to_columnstring
{
	my $self = shift;
	my ($dfltbit, $setbit) = ($self->has_min_bits)? qw(0 1): qw(1 0);
	my @bitlist = ($dfltbit) x (1 << $self->width);

	my @terms;

	push @terms, @{$self->minterms} if ($self->has_minterms);
	push @terms, @{$self->maxterms} if ($self->has_maxterms);

	map {$bitlist[$_] = $setbit} @terms;

	if ($self->has_dontcares)
	{
		map {$bitlist[$_] = $self->dc} (@{ $self->dontcares});
	}

	return join "", @bitlist;
}

#
# Take a column string and return array refs usable as parameters for
# minterm, maxterm, and don't-care attributes.
#
sub break_columnstring
{
	my $self = shift;
	my @bitlist = split(//, $self->columnstring);
	my $x = 0;

	my(@maxterms, @minterms, @dontcares);

	for (@bitlist)
	{
		push @minterms, $x if ($_ eq '1');
		push @maxterms, $x if ($_ eq '0');
		push @dontcares, $x if ($_ eq $self->dc);
		$x++;
	}

	return (\@minterms, \@maxterms, \@dontcares);
}

sub complement_terms
{
	my $self = shift;
	my @bitlist = (0 .. (1 << $self->width) - 1);
	my @termlist = @{$self->dontcares} if ($self->has_dontcares);

	if ($self->has_minterms)
	{
		push @termlist, @{ $self->minterms };
	}
	else
	{
		push @termlist, @{ $self->maxterms };
	}

	return get_complement([\@termlist, \@bitlist]);
}

#
# Build another Quine-McCluskey object that's the complement
# of the existing object.
#
sub complement
{
	my $self = shift;
	my %term;

	$term{dontcares} = [@{$self->dontcares}] if ($self->has_dontcares);

	if ($self->has_minterms)
	{
		$term{minterms} = [$self->complement_terms()];
	}
	else
	{
		$term{maxterms} = [$self->complement_terms()];
	}

	my $title = "Complement of '" . $self->title() . "'";

	return Algorithm::QuineMcCluskey->new(
		title => $title,
		width => $self->width,
		dc => $self->dc,
		vars => [ @{$self->vars} ],
		%term
	);
}

#
# Build another Quine-McCluskey object that's the dual
# of the existing object.
#
sub dual
{
	my $self = shift;
	my $last = (1 << $self->width) - 1;
	my %term;

	$term{dontcares} = [@{$self->dontcares}] if ($self->has_dontcares);

	my @dualterms = sort map {$last - $_} $self->complement_terms();

	if ($self->has_minterms)
	{
		$term{minterms} = [@dualterms];
	}
	else
	{
		$term{maxterms} = [@dualterms];
	}

	my $title = "Dual of '" . $self->title() . "'";

	return Algorithm::QuineMcCluskey->new(
		title => $title,
		width => $self->width,
		dc => $self->dc,
		vars => [ @{$self->vars} ],
		%term
	);
}

sub all_bit_terms
{
	my $self = shift;
	my @terms;

	push @terms, $self->minmax_bit_terms();
	push @terms, @{ $self->dc_bits } if ($self->has_dc_bits);
	return sort @terms;
}

sub minmax_bit_terms
{
	my $self = shift;

	return ($self->has_min_bits)? @{$self->min_bits}: @{$self->max_bits};
}

sub generate_primes
{
	my $self = shift;
	my @bits;
	my %implicant;

	#
	# Separate into bins based on number of 1's (the weight).
	#
	### generate_primes() group the bit terms
	#
	for ($self->all_bit_terms())
	{
		push @{$bits[0][ matchcount($_, '1') ]}, $_;
	}

	#
	# Now for each level, we look for terms that can be absorbed into
	# simpler product terms (for example, _ab_c + ab_c can be simplified
	# to b_c).
	#
	# Level 0 consists of the fundemental
	# product terms; level 1 consists of pairs of fundemental terms
	# that have a variable in common; level 2 consists of pairs of pairs
	# that have a variable in common; and so on until we're out of
	# levels (number of variables) or cannot find any more products
	# with terms in common.
	#
	for my $level (0 .. $self->width)
	{
		#
		# Skip if we haven't generated data for this level.
		#
		last unless ref $bits[$level];

		#
		### Level: $level
		### grouped by bit count: $bits[$level]
		#
		# Find pairs with Hamming distance of 1 (i.e., a weight
		# difference of 1).
		#
		for my $low (0 .. $#{ $bits[$level] })
		{
			#
			# These nested for-loops get all permutations
			# of adjacent sets.
			#
			for my $lv (@{ $bits[$level][$low] })
			{
				my %nextlvlimp;

				#
				# Initialize the implicant as unused.
				#
				$implicant{$lv} //= 0;

				#
				# Skip ahead if there are no terms at
				# this level.
				#
				next unless ref $bits[$level][$low + 1];

				for my $hv (@{ $bits[$level][$low + 1] })
				{
					#
					# Initialize the implicant.
					#
					$implicant{$hv} //= 0;

					#
					# If there are matching terms, save
					# the new implicant at the next 'level',
					# creating the level if it doesn't exist.
					#
					my $hd1pos = hammingd1pos($lv, $hv);
					if ($hd1pos != -1)
					{
						my $new = $lv;	# or $hv
						substr($new, $hd1pos, 1) = $self->dc;

						#
						### Compared: $lv
						### to      : $hv
						### pushing : $new
						#
						# Save the new implicant to the
						# next level, then mark the two
						# values as used.
						#
						push @{ $bits[$level + 1][$low + 1] }, $new unless (exists $nextlvlimp{$new});
						$nextlvlimp{$new} = 1;
						$implicant{$lv} = 1;
						$implicant{$hv} = 1;
					}
					else
					{
						#
						### Compared: $lv
						### to      : $hv
						### No push
						#
					}
				}
			}
		}
	}

	#
	### generate_primes() implicant hash (we use the unmarked entries
	### [i.e., prime => 0] ) : %implicant
	#

	#
	# For each unmarked (value == 0) implicant, match it against the
	# minterms (or maxterms). The resulting hash of arrays is our
	# set of prime implicants.
	#
	my %p;

	for my $unmarked (grep { !$implicant{$_} } keys %implicant)
	{
		my @matched = maskedmatch($unmarked, $self->minmax_bit_terms());
		$p{$unmarked} = [@matched] if (@matched);
	}

	#
	### generate_primes() -- prime implicants: hasharray(\%p)
	#
	return \%p;
}

sub generate_covers
{
	my $self = shift;

	return [ $self->recurse_solve($self->get_primes, 0) ];
}

sub generate_essentials
{
	my $self = shift;

	my $p = $self->get_primes;
	my %e = find_essentials($p, $self->minmax_bit_terms());

	### generate_essentials() -- essentials: hasharray(\%e)

	return [sort keys %e];
}

sub to_boolean
{
	my $self = shift;
	my($cref) = @_;
	my $is_sop = $self->has_min_bits;
	my $w = $self->width;

	#
	### to_boolean() called with: arrayarray([$cref])
	#
	# Group separators (grouping character pairs)
	#
	my($gsb, $gse) = ('(', ')');

	#
	# Group joiner string, depending on whether this
	# is a sum-of-products or product-of-sums.
	#
	my $gj = $is_sop ? ' + ': '';

	my @covers = @$cref;

	#
	# Check for the special case where the covers are a single
	# expression of nothing but dc characters (e.g., "----").
	# This is caused when all of the terms (including
	# don't-care) are covered, resulting in an equation that would
	# be simply "(1)" (or "(0)" if using maxterms). Since the usual
	# translation will return "()", this has to checked.
	#
	if ($#covers == 0 and $covers[0] =~ /[^01]{$w}/)
	{
		return ($is_sop)? "(1)": "(0)";
	}

	@covers = sort @covers if ($self->order_by eq 'covers');

	my @exprns = map {$gsb . $self->to_boolean_term($_, $is_sop) . $gse} @covers;
	@exprns = sort @exprns if ($self->order_by eq 'vars');

	return join $gj, @exprns;
}

#
# Convert an individual term or prime implicant to a boolean variable string.
#
sub to_boolean_term
{
	my $self = shift;
	my($term, $is_sop) = @_;

	#
	# Element joiner and match condition
	#
	my($ej, $cond) = $is_sop ? ('', 1) : (' + ', 0);
	tie my $var, 'Tie::Cycle', [ @{$self->vars} ];

	my $varstring = join $ej, map {
			my $var = $var;	# Activate cycle even if not used
			$_ eq $self->dc ? () : $var . ($_ == $cond ? '' : "'")
		} split(//, $term);

	return $varstring;
}

sub solve
{
	my $self = shift;
	my $c = $self->get_covers();

	### solve -- get_covers() returned: arrayarray($c)

	return $self->to_boolean($c->[0]);
}

sub all_solutions
{
	my $self = shift;
	my $c = $self->get_covers();

	### solve -- get_covers() returned: arrayarray($c)

	return map {$self->to_boolean($_)} @$c;
}

#
# recurse_solve
#
# Recursive divide-and-conquer solver
#
# "To reduce the complexity of the prime implicant chart:
#
# 1. Select all the essential prime impliciants. If these PIs cover all
# minterms, stop; otherwise go the second step.
#
# 2. Apply Rules 1 and 2 to eliminate redundant rows and columns from
# the PI chart of non-essential PIs.  When the chart is thus reduced,
# some PIs will become essential (i.e., some columns will have a single
# 'x'. Go back to step 1."
#
# Introduction To Logic Design, by Sajjan G. Shiva, page 129.
#
sub recurse_solve
{
	my $self = shift;
	my %primes = %{ $_[0] };
	my $level = $_[1];
	my @prefix;
	my @covers;
	my @essentials_keys;

	#
	##### recurse_solve() level: $level
	##### recurse_solve() called with: "\n" . chart(\%primes, $self->width)
	#
	
	my %ess = find_essentials(\%primes, $self->minmax_bit_terms());

	#
	##### Begin prefix/essentials loop.
	#
	do
	{
		#
		##### recurse_solve() essentials: %ess
		#
		# Remove the essential prime implicants from
		# the prime implicants table.
		#
		@essentials_keys = keys %ess;

		#
		##### Purging prime hash of: "[" . join(", ", sort @essentials_keys) . "]"
		#
		purge_elements(\%primes, @essentials_keys);
		push @prefix, grep { $ess{$_} > 0} @essentials_keys;

		##### recurse_solve() @prefix now: "[" . join(", ", sort @prefix) . "]"

		#
		# Now eliminate dominated rows and columns.
		#
		# Rule 1: A row dominated by another row can be eliminated.
		# Rule 2: A column that dominated another column can be eliminated.
		#
		my @rows = row_dominance(\%primes, 1);
		#### row_dominance called with primes: "\n" . chart(\%primes, $self->width)
		#### row_dominance returns for removal: "[" . join(", ", @rows) . "]"
		delete $primes{$_} for (@rows);

		my %cols = columns(\%primes, $self->minmax_bit_terms());
		my @cols = row_dominance(\%cols, 0);
		#### row_dominance called with primes (rotated): "\n" . chart(\%cols, $self->width)
		#### row_dominance returns for removal: "[" . join(", ", @cols) . "]"
		remels($_, \%primes) for (@cols);

		%ess = find_essentials(\%primes, $self->minmax_bit_terms());

		##### recurse_solve() essentials after purge/dom: %ess

	} until (is_LequivalentR([
			[ @essentials_keys ] => [ keys %ess ]
			]));

	return [ reverse sort @prefix ] unless (keys %primes);

	#
	##### recurse_solve() Primes after loop: "\n" . chart(\%primes, $self->width)
	#

	#
	# Find the term that has the least number of prime implicants
	# covering it. Then having found it, make a list of those
	# prime implicants, and use that list to figure out the best
	# set to cover the rest of the terms.
	#
	my $term = least_covered(\%primes, $self->minmax_bit_terms());
	my @ta = grep { countels($term, $primes{$_}) } keys %primes;

	#
	##### Least-covered term returned is: $term
	##### Prime implicants that cover term are: "[" . join(", ", @ta) . "]"
	#
	# Make a copy of the section of the prime implicants
	# table that don't cover that term.
	#
	my %r = map {
		$_ => [ grep { $_ ne $term } @{ $primes{$_} } ]
	} keys %primes;

	#
	# For each such cover, recursively solve the table with that column
	# removed and add the result(s) to the covers table after adding
	# back the removed term.
	#
	for my $ta (@ta)
	{
		my (@c, @results);
		my %reduced = %r;

		#
		# Use this prime implicant -- delete its row and columns
		#
		##### Purging reduced hash of: $ta
		#
		purge_elements(\%reduced, $ta);

		if (keys %reduced and scalar(@c = $self->recurse_solve(\%reduced, $level + 1)))
		{
			#
			##### recurse_solve() at level: $level
			##### returned (in loop): arrayarray(\@c)
			#
			@results = map { [ reverse sort (@prefix, $ta, @$_) ] } @c;
		}
		else
		{
			@results = [ reverse sort (@prefix, $ta) ]
		}

		push @covers, @results;

		#
		##### Covers now at: arrayarray(\@covers)
		#
	}

	#
	##### Weed out the duplicated and expensive solutions.
	#
	@covers = uniqels @covers;

	if ($self->minonly and scalar @covers > 1)
	{
		my @weededcovers = shift @covers;
		my $mincost = matchcount(join('', @{$weededcovers[0]}), "[01]");

		for my $c (@covers)
		{
			my $cost = matchcount(join('', @$c), "[01]");

			#
			##### Cover: join(',', @$c)
			##### Cost: $cost
			#
			next if ($cost > $mincost);

			if ($cost < $mincost)
			{
				$mincost = $cost;
				@weededcovers = ();
			}
			push @weededcovers, $c;
		}
		@covers = @weededcovers;
	}

	#
	##### Covers is: arrayarray(\@covers)
	##### after the weeding out.
	#
	# Return our covers table to be treated similarly one level up.
	#
	return @covers;
}

1;
__END__

=head1 NAME

Algorithm::QuineMcCluskey - solve Quine-McCluskey set-cover problems

=head1 SYNOPSIS

    use Algorithm::QuineMcCluskey;

    #
    # Five-bit, 12-minterm Boolean expression test with don't-cares
    #
    my $q = Algorithm::QuineMcCluskey->new(
        width => 5,
        minterms => [ 0, 5, 7, 8, 10, 11, 15, 17, 18, 23, 26, 27 ],
        dontcares => [ 2, 16, 19, 21, 24, 25 ]
    );

    my $result = $q->solve();

or

    use Algorithm::QuineMcCluskey;

    my $q = Algorithm::QuineMcCluskey->new(
	width => 5,
        columnstring => '10-0010110110001-11-0-01--110000'
    );

    my $result = $q->solve();

In either case C<$result> will be C<"(AC') + (A'BDE) + (B'CE) + (C'E')">.

The strings that represent the covered terms are also viewable:


    use Algorithm::QuineMcCluskey;

    #
    # Five-bit, 12-minterm Boolean expression test with don't-cares
    #
    my $q = Algorithm::QuineMcCluskey->new(
        width => 4,
        minterms => [ 1, 6, 7, 8, 11, 13, 15],
    );

    my @covers = $q->get_covers();

    print join(", ", @covers[0];

Will print out

    '0001', '011-', '1-11', '1000', '11-1'
    (A'B'C'D) + (A'BC) + (ACD) + (AB'C'D') + (ABD)

=head1 DESCRIPTION

This module minimizes
L<Boolean expressions|https://en.wikipedia.org/wiki/Boolean_algebra> using the
L<Quine-McCluskey algorithm|https://en.wikipedia.org/wiki/Quine%E2%80%93McCluskey_algorithm>.

=head2 Object Methods

=head3 new([<attribute> => value, ...])

Creates the QuineMcCluskey object. The attributes are:

=over 4

=item 'width'

The number of variables (columns) in the Boolean expression.

This is a required attribute.

=item 'minterms'

An array reference of terms representing the 1-values of the
Boolean expression.

=item 'maxterms'

An array reference of terms representing the 0-values of the
Boolean expression. This will also indicate that you want the
expression in product-of-sum form, instead of the default
sum-of-product form.

=item 'dontcares'

An array reference of terms representing the don't-care-values of the
Boolean expression. These represent inputs that simply shouldn't happen
(e.g., numbers 11 through 15 in a base 10 system), and therefore don't
matter to the result.

=item 'columnstring'

Present the entire list of values of the boolean expression as a single
string. The values are ordered from left to right in the string. For example,
a simple two-variable AND equation would have a string "0001".

=item 'dc'

I<Default value: '-'>

Change the representation of the don't-care character. The don't-care character
is used both in the columnstring, and internally as a place holder for
eliminated variables in the equation. Some of those internals
may be examined via other methods.

=item 'title'

A title for the problem you are solving.

=item 'vars'

I<Default value: ['A' .. 'Z']>

The variable names used to form the equation. The names will be taken from
the leftmost first:

    my $f1 = Algorithm::QuineMcCluskey->new(
        width => 4,
        maxterms => [1 .. 11, 13, 15],
	vars => ['w' .. 'z']
    );

The names do not have to be single characters, e.g.:

        vars => ['a1', 'a0', 'b1', 'b0']

=back

=head3 solve()

Returns a string of the Boolean equation.

For now, the form of the equation is set by the choice of terms used
to create the object. If you use the minterms attribute, the equation
will be returned in sum-of-product form. If you use the maxterms
attribute, the equation will be returned in product-of-sum form.

Using the columnstring attribute is the same as using the minterm
attribute as far as solve() is concerned.

It is possible that there will be more than one equation that solves the
boolean expression. Therefore solve() can return a different (but equally
valid) equation on separate runs. You can have the full list of possible
equations by using L</all_solutions>. Likewise, the terms that describe
the solution (before they are converted with the variable names) are
returned with L</get_covers()>, described below.

=head3 all_solutions()

Return an array of strings that represent the Boolean equation.

It is often the case that there will be more than one equation that
covers the terms.

    my @sol = $q->all_solutions();

    print "    ", join("\n    ", @sol), "\n";

The first equation in the list will be the equation returned by L</solve>.


=head3 complement()

Returns a new object that's the complement of the existing object:

    my $qc = $q->complement();
    print $qc->solve(), "\n";

Prints

    (ABC) + (A'B'D'E) + (BD'E) + (CE')

=head3 dual()

Returns a new object that's the dual of the existing object:

    my $qd = $q->dual();
    print $qd->solve(), "\n";

Prints

    (ABCE') + (A'B'C') + (B'DE') + (C'E)

=head3 get_primes()

Returns the prime implicants of the boolean expression, as a hash
reference. The keys of the hash are the prime implicants, while
the values of the hash are arrays of the terms each implicant covers.

    use Algorithm::QuineMcCluskey;

    my $q = Algorithm::QuineMcCluskey->new(
        width => 4,
        minterms => [0, 2, 3, 4, 5, 10, 12, 13, 14, 15]
        );

    #
    # Remember, get_primes() returns a hash reference.
    #
    my $prime_ref = $q->get_primes();
    print join(", ", sort keys %{$prime_ref}), "\n";

prints

    -010, -10-, 0-00, 00-0, 001-, 1-10, 11--

See the chart() function in Algorithm::QuineMcCluskey::Format
for an example of the prime implicant/term chart.

=head3 get_essentials()

Returns the essential prime implicants of the boolean expression, as an array
reference. The array elements are the prime implicants that are essential,
that is, the only ones that happen to cover certain terms in the expression.

    use Algorithm::QuineMcCluskey;

    my $q = Algorithm::QuineMcCluskey->new(
        width => 4,
        minterms => [0, 2, 3, 4, 5, 10, 12, 13, 14, 15]
        );

    my $ess_ref = $q->get_essentials();
    print join(", ", @{$ess_ref}), "\n";

prints

    -10-, 001-, 11--

=head3 get_covers()

Returns all of the reduced implicant combinations that cover the booelan
expression.

The implicants are in a form that combines 1, 0, and the don't-care character
(found and set with the C<dc> attribute). These are used by L</solve()> to
create a boolean equation that solves the set of minterms or maxterms.

It is possible that there will be more than one equation that solves a boolean
expression. The solve() method returns a minimum set, and all_solutions()
show the complete set of solutions found by the algorithm.

But if you want to see how the solutions match up with their associated
covers, you may use this:

    use Algorithm::QuineMcCluskey;

    my $q = Algorithm::QuineMcCluskey->new(
        width => 4,
        minterms => [0, 2, 3, 4, 5, 10, 12, 13, 14, 15]
        );

    #
    # get_covers() returns an array ref of arrays.
    #
    my $covers = $q->get_covers();

    for my $idx (0 .. $#{$covers})
    {
        my @cvs = sort @{$covers->[$idx]};

        #
        # The raw ones, zeroes, and dont-care characters.
        #
        print "'", join("', '",  @cvs), "' => ";

        #
        # And the resulting boolean equation.
        #
        print $q->to_boolean(\@cvs), "\n";
    }

prints

    '-010', '-10-', '00-0', '001-', '11--' => (B'CD') + (BC') + (A'B'D') + (A'B'C) + (AB)
    '-10-', '00-0', '001-', '1-10', '11--' => (BC') + (A'B'D') + (A'B'C) + (ACD') + (AB)
    '-010', '-10-', '0-00', '001-', '11--' => (B'CD') + (BC') + (A'C'D') + (A'B'C) + (AB)
    '-10-', '0-00', '001-', '1-10', '11--' => (BC') + (A'C'D') + (A'B'C) + (ACD') + (AB)


Note the use of the method to_boolean() in the loop. This is the method
solve() uses to create its equation, by passing it the first of the list
of covers.

=head3 to_columnstring()

Return a string made up of the function's column's values. Position 0 in
the string is the 0th row of the column, and so on. The string will consist
of zeros, ones, and the don't-care character (which by default is '-').

    my $column = $self->to_columnstring();

=head1 AUTHOR

Darren M. Kulp B<darren@kulp.ch>

John M. Gamble B<jgamble@cpan.org> (current maintainer)

=cut

