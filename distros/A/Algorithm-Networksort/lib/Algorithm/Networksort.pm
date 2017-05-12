package Algorithm::Networksort;

use 5.010001;

use Moose;
use Moose::Exporter;
use namespace::autoclean;

use Carp;
use integer;

#
# Three # for "I am here" messages, four # for variable dumps.
# Five # for sort tracking.
#
#use Smart::Comments ('####');

#
# Export a couple of convenience functions:
# nwsrt(), which is shorthand for Algorithm::Networksort->new();
# and algorithms(), which gives a list of algorithm keys.
#
Moose::Exporter->setup_import_methods(
	as_is => [\&nwsrt_algorithms, \&nwsrt_title, \&nwsrt],
);

our $VERSION = '2.01';

#
# Our one use of overload, because default
# printing is useful.
#
use overload
	'""'	=> \&_stringify;

#
# Names for the algorithm keys.
#
my %algname = (
	bosenelson => "Bose-Nelson Sort",
	batcher => "Batcher's Mergesort",
	hibbard => "Hibbard's Sort",
	bubble => "Bubble Sort",
	bitonic => "Bitonic Sort",
	oddeventrans => "Odd-Even Transposition Sort",
	balanced => "Balanced",
	oddevenmerge => "Batcher's Odd-Even Merge Sort",
);

#
# Default parameters for SVG, EPS, and text graphing.
#
my %graphset = (
	hz_sep => 12,
	hz_margin => 18,
	vt_sep => 12,
	vt_margin => 21,
	indent => 9,
	radius => 2,
	stroke_width => 2,
	inputbegin => "o-",
	inputline => "---",
	inputcompline => "-|-",
	inputend => "-o\n",
	compbegin => "-^-",
	compend => "-v-",
	gapbegin => "  ",
	gapcompline => " | ",
	gapnone => "   ",
	gapend => "  \n",
);

#
# Default graphing color parameters.
#
my %colorset = (
	foreground => undef,
	inputbegin => undef,
	inputline => undef,
	inputend => undef,
	compline=> undef,
	compbegin => undef,
	compend => undef,
	background => undef,
);

has algorithm => (
	isa => 'Str', is => 'ro',
	default => 'bosenelson',
);

has inputs => (
	isa => 'Int', is => 'ro', required => 1,
);

has nwid => (
	isa => 'Str', is => 'rw', required => 0,
	predicate => 'has_nwid',
);

has comparators => (
	isa => 'ArrayRef[ArrayRef[Int]]', is => 'rw', required => 0,
	predicate => 'has_comparators',
);

has network => (
	isa => 'ArrayRef[ArrayRef[Int]]', is => 'rw', required => 0,
	predicate => 'has_network',
);

has ['depth', 'length'] => (
	isa => 'Int', is => 'rw', required => 0,
	init_arg => 0,
);

has creator => (
	isa => 'Str', is => 'ro', required => 0,
	default => sub { return "Perl module " . __PACKAGE__ .  ", " .
		"version $VERSION";}
);

has title => (
	isa => 'Str', is => 'rw', required => 0,
	predicate => 'has_title'
);

has formats => (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	init_arg => undef,
);

has grouped_format => (
	isa => 'Str', is => 'rw', required => 0,
	default => "%s,\n",
);

has index_base => (
	isa => 'ArrayRef[Value]', is => 'rw', required => 0,
);

#
# Variables to track sorting statistics
#
my $swaps = 0;

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Networksort - Create Sorting Networks.

=begin html

<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink" width="105" height="61" viewbox="0 0 105 61">
  <rect width="100%" height="100%" fill="#eeeeee" />
  <defs>
    <g id="I_41c1" style="fill:none; stroke-width:2" >
      <circle style="stroke:#206068" cx="18" cy="0" r="2" />
      <line style="stroke:#206068" x1="18" y1="0" x2="87" y2="0" />
      <circle style="stroke:#206068" cx="87" cy="0" r="2" />
    </g>

    <g id="C1_41c1" style="stroke-width:2" >
      <line style="fill:#206068; stroke:#206068" x1="0" y1="0" x2="0" y2="15" />
      <circle style="fill:#206068; stroke:#206068" cx="0" cy="0" r="2" />
      <circle style="fill:#206068; stroke:#206068" cx="0" cy="15" r="2" />
    </g>
    <g id="C2_41c1" style="stroke-width:2" >
      <line style="fill:#206068; stroke:#206068" x1="0" y1="0" x2="0" y2="30" />
      <circle style="fill:#206068; stroke:#206068" cx="0" cy="0" r="2" />
      <circle style="fill:#206068; stroke:#206068" cx="0" cy="30" r="2" />
    </g>
  </defs>

  <g id="N_41c1">
    <use xlink:href="#I_41c1" y="8" /> <use xlink:href="#I_41c1" y="23" />
    <use xlink:href="#I_41c1" y="38" /> <use xlink:href="#I_41c1" y="53" />

    <use xlink:href="#C1_41c1" x="27" y="8" /> <use xlink:href="#C1_41c1" x="27" y="38" />
    <use xlink:href="#C2_41c1" x="44" y="8" /> <use xlink:href="#C2_41c1" x="61" y="23" />
    <use xlink:href="#C1_41c1" x="78" y="23" />
  </g>
</svg>

=end html

=head1 SYNOPSIS

    use Algorithm::Networksort;

    my $inputs = 4;
    my $algorithm = "bosenelson";

    #
    # Generate the sorting network (a list of comparators).
    #
    my $nw = Algorithm::Networksort->new(inputs =>$inputs
                                        algorithm => $algorithm);

    #
    # Print the comparator list using the default format,
    # and print a graph of the list.
    #
    print $nw->formatted(), "\n";
    print $nw->graph_text(), "\n";

    #
    # Set up a pretty SVG image.
    #
    $nw->graphsettings(vt_margin => 8, vt_sep => 13, hz_sep=>15);
    $nw->colorsettings(foreground => "#206068", background => "#c8c8c8");
    print $nw->graph_svg();

=head1 DESCRIPTION

This module will create sorting networks, a sequence of comparisons
that do not depend upon the results of prior comparisons.

Since the sequences and their order never change, they can be very
useful if deployed in hardware, or if used in software with a compiler
that can take advantage of parallelism. Unfortunately a sorting network cannot
be used for generic run-time sorting like quicksort, since the arrangement of
the comparisons is fixed according to the number of elements to be
sorted.

This module's main purpose is to create compare-and-swap macros (or
functions, or templates) that one may insert into source code. It may
also be used to create images of the sorting networks in either encapsulated
postscript (EPS), scalar vector graphics (SVG), or in "ascii art" format.

=head2 Exported Functions

For convenience's sake, there are three exported functions to save typing
and inconvenient look-ups.

=head3 nwsrt()

Simple function to save the programmer from the agony of typing
C<Algorithm::Networksort-E<gt>new()>:

    use Algorithm::Networksort;

    my $nw = nwsrt(inputs => 13, algorithm => 'bitonic');

=cut

sub nwsrt { return __PACKAGE__->new(@_); }


=head3 nwsrt_algorithms()

Return a sorted list algorithm choices. Each one is a valid key for the
algorithm argument of Algorithm::Networksort->new(), or L<nwsrt()>.

    use Algorithm::Networksort;

    my @alg_keys = nwsrt_algorithms();

    print "The available keys for the algorithm argument are (",
            join(", ", @alg_keys), ")\n";

Or, for an even less likely example:

    my $inputs = 6;

    for my $al (nwsrt_algorithms())
    {
    	my $nw = nwsrt(inputs => $inputs, algorithm => $al);
    	print $nw->title(), "\n", $nw, "\n";
    }

=cut

sub nwsrt_algorithms
{
	return sort keys %algname;
}

=head3 nwsrt_title

Return a descriptive title for the network, given an algorithm's key name.

    $title = nwsrt_title($key);

These are the titles for the available algorithms. By themselves, they provide
a readable list of choices for an interactive program. They are not to be
confused with a sorting network's title, which may be set by the programmer.

=cut

sub nwsrt_title
{
	my $key = shift;
	
	unless (exists $algname{$key})
	{
		carp "Unknown name '$key'.";
		return "";
	}

	return $algname{$key}{title};
}

=head2 Methods

=head3 new()

    $nw1 = Algorithm::Networksort->new(inputs => $inputs,
                                       algorithm => 'batcher');

    $nw2 = Algorithm::Networksort->new(inputs => $inputs,
                                       algorithm => 'oddevenmerge');

Returns an object that contains, among other things, a list of comparators that
can sort B<$inputs> items. The algorithm for generating the list may be chosen,
but by default the sorting network is generated by the Bose-Nelson algorithm.

The choices for the B<algorithm> key are

=over 3

=item 'bosenelson'

Use the Bose-Nelson algorithm to generate the network. This is the most
commonly implemented algorithm, recursive and simple to code.

=item 'hibbard'

Use Hibbard's algorithm. This iterative algorithm was developed after the
Bose-Nelson algorithm was published, and produces a different network
"... for generating the comparisons one by one in the order in which
they are needed for sorting," according to his article (see below).

=item 'batcher'

Use Batcher's Merge Exchange algorithm. Merge Exchange is a real sort, in
that in its usual form (for example, as described in Knuth) it can handle
a variety of inputs. But while sorting it always generates an identical set of
comparison pairs per array size, which lends itself to sorting networks.

=item 'bitonic'

Use Batcher's bitonic algorithm. A bitonic sequence is a sequence that
monotonically increases and then monotonically decreases. The bitonic sort
algorithm works by recursively splitting sequences into bitonic sequences
using so-called "half-cleaners". These bitonic sequences are then merged
into a fully sorted sequence. Bitonic sort is a very efficient sort and
is especially suited for implementations that can exploit network
parallelism.

=item 'oddevenmerge'

Use Batcher's Odd-Even Merge algorithm. This sort works in a similar way
to a regular merge sort, except that in the merge phase the sorted halves
are merged by comparing even elements separately from odd elements. This
algorithm creates very efficient networks in both comparators and stages.

=item 'bubble'

Use a naive bubble-sort/insertion-sort algorithm. Since this algorithm
produces more comparison pairs than the other algorithms, it is only
useful for illustrative purposes.

=item 'oddeventrans'

Use a naive odd-even transposition sort. This is a primitive sort closely
related to bubble sort except it is more parallel. Because other algorithms
are more efficient, this sort is included for illustrative purposes.

=item 'balanced'

This network is described in the 1983 paper "The Balanced Sorting Network"
by M. Dowd, Y. Perl, M Saks, and L. Rudolph. It is not a particularly
efficient sort but it has some interesting properties due to the fact
that it is constructed as a series of successive identical sub-blocks,
somewhat like with 'oddeventrans'.

=item 'none'

Do not generate a set of comparators. Instead, take the set from an
outside source, using the C<comparators> option.

    #
    # Test our own 5-input network.
    #
    @cmptr = ([1,2], [0,2], [0,1], [3,4], [0,3], [1,4], [2,4], [1,3], [2,3]);

    $nw = Algorithm::Networksort->new(inputs => 5,
                algorithm => 'none',
                comparators => [@cmptr]);

Internally, this is what L<nwsrt_best()|Algorithm::Networksort::Best/nwsrt_best()>
of L<Algorithm::Networksort::Best> uses.

=back

=cut

sub BUILD
{
	my $self = shift;
	my $alg = $self->algorithm();
	my $inputs = $self->inputs();

	my @network;
	my @grouped;

	#
	# Catch errors
	#
	croak "Input size must be 2 or greater" if ($inputs < 2);

	#
	# Providing our own-grown network?
	#
	if ($alg eq 'none')
	{
		croak "No comparators provided" unless ($self->has_comparators);
		$self->length(scalar @{ $self->comparators });

		#
		# Algorithm::Networksort::Best will set these, so
		# only go through with this if this is a user-provided
		# sequence of comparators.
		#
		unless ($self->has_network and $self->depth > 0)
		{
			@grouped = $self->group();
			$self->network($self->comparators);
			$self->depth(scalar @grouped);
			$self->network([map { @$_ } @grouped]);
			$self->title("Unknown $inputs-Inputs Comparator Set") unless ($self->has_title());
		}

		$self->nwid("nonalgorithmic-" . sprintf("%02d", $inputs)) unless ($self->has_nwid());

		return $self;
	}

	croak "Unknown algorithm '$alg'" unless (exists $algname{$alg});
	$self->nwid($alg . sprintf("%02d", $inputs));

	@network = bosenelson($inputs) if ($alg eq 'bosenelson');
	@network = hibbard($inputs) if ($alg eq 'hibbard');
	@network = batcher($inputs) if ($alg eq 'batcher');
	@network = bitonic($inputs) if ($alg eq 'bitonic');
	@network = bubble($inputs) if ($alg eq 'bubble');
	@network = oddeventransposition($inputs) if ($alg eq 'oddeventrans');
	@network = balanced($inputs) if ($alg eq 'balanced');
	@network = oddevenmerge($inputs) if ($alg eq 'oddevenmerge');

	$self->title($algname{$alg}  . " for N = " . $inputs) unless ($self->has_title);
	$self->length(scalar @network);
	$self->comparators(\@network);	# The 'raw' list of comparators.

	#
	# Re-order the comparator list using the parallel grouping for
	# the graphs. The resulting parallelism means less stalling
	# when used in a pipeline.
	#
	@grouped = $self->group();

	#
	#### @grouped
	#
	$self->depth(scalar @grouped);
	$self->network([map { @$_ } @grouped]);

	return $self;
}

=head3 comparators()

The comparators in their 'raw' form, as generated by its algorithm.

For the comparators re-ordered in such a way as to take advantage
of parallelism, see L<network()>.

=head3 network()

Returns the comparators re-ordered from the 'raw' order, to provide a
parallelized version of the comparator list; the best order possible to
prevent stalling in a CPU's pipeline.

This is the form used when printing the sorting network using L<formats()>.

=cut

=head3 algorithm_name()

Return the full text name of the algorithm, given its key name.

=cut

sub algorithm_name
{
	my $self = shift;
	my $algthm = $_[0] // $self->algorithm();

	return $algname{$algthm} if (defined $algthm);
	return "";
}

#
# @network = hibbard($inputs);
#
# Return a list of two-element lists that comprise the comparators of a
# sorting network.
#
# Translated from the ALGOL listed in T. N. Hibbard's article, A Simple
# Sorting Algorithm, Journal of the ACM 10:142-50, 1963.
#
# The ALGOL code was overly dependent on gotos.  This has been changed.
#
sub hibbard
{
	my $inputs = shift;
	my @comparators;
	my($bit, $xbit, $ybit);

	#
	# $t = ceiling(log2($inputs - 1)); but we'll
	# find it using the length of the bitstring.
	#
	my $t = unpack("B32", pack("N", $inputs - 1));
	$t =~ s/^0+//;
	$t = length $t;

	my $lastbit = 1 << $t;

	#
	# $x and $y are the comparator endpoints.
	# We begin with values of zero and one.
	#
	my($x, $y) = (0, 1);

	while (1 == 1)
	{
		#
		# Save the comparator pair, and calculate the next
		# comparator pair.
		#
		### hibbard() top of loop:
		#### @comparators
		#
		push @comparators, [$x, $y];

		#
		# Start with a check of X and Y's respective bits,
		# beginning with the zeroth bit.
		#
		$bit = 1;
		$xbit = $x & $bit;
	 	$ybit = $y & $bit;

		#
		# But if the X bit is 1 and the Y bit is
		# zero, just clear the X bit and move on.
		#
 		while ($xbit != 0 and $ybit == 0)
		{
			$x &= ~$bit;

			$bit <<= 1;
			$xbit = $x & $bit;
	 		$ybit = $y & $bit;
		}

 		if ($xbit != 0)		#  and $ybit != 0
		{
			$y &= ~$bit;
			next;
		}

		#
		# The X bit is zero if we've gotten this far.
		#
 		if ($ybit == 0)
		{
			$x |= $bit;
			$y |= $bit;
			$y &= ~$bit if ($y > $inputs - 1);
			next;
		}

		#
		# The X bit is zero, the Y bit is one, and we might
		# return the results.
		#
		do
		{
			return @comparators if ($bit == $lastbit);

			$x &= ~$bit;
			$y &= ~$bit;

			$bit <<= 1;	# Next bit.

			if ($y & $bit)
			{
				$x &= ~$bit;
				next;
			}

			$x |= $bit;
			$y |= $bit;
		} while ($y > $inputs - 1);

		#
		# No return, so loop onwards.
		#
		$bit = 1 if ($y < $inputs - 1);
		$x &= ~$bit;
		$y |= $bit;
	}
}

#
# @network = bosenelson($inputs);
#
# Return a list of two-element lists that comprise the comparators of a
# sorting network.
#
# The Bose-Nelson algorithm.
#
sub bosenelson
{
	my $inputs = shift;

	return bn_split(0, $inputs);
}

#
# @comparators = bn_split($i, $length);
#
# The helper function that divides the range to be sorted.
#
# Note that the work of splitting the ranges is performed with the
# 'length' variables.  The $i variable merely acts as a starting
# base, and could easily have been 1 to begin with.
#
sub bn_split
{
	my($i,  $length) = @_;
	my @comparators = ();

	#
	### bn_split():
	#### $i
	#### $length
	#

	if ($length >= 2)
	{
		my $mid = $length/2;

		push @comparators, bn_split($i, $mid);
		push @comparators, bn_split($i + $mid, $length - $mid);
		push @comparators, bn_merge($i, $mid, $i + $mid, $length - $mid);
	}

	#
	### bn_split() returns
	#### @comparators
	#
	return @comparators;
}

#
# @comparators = bn_merge($i, $length_i, $j, $length_j);
#
# The other helper function that adds comparators to the list, for a
# given pair of ranges.
#
# As with bn_split, the different conditions all depend upon the
# lengths of the ranges.  The $i and $j variables merely act as
# starting bases.
#
sub bn_merge
{
	my($i, $length_i, $j, $length_j) = @_;
	my @comparators = ();

	#
	### bn_merge():
	#### $i
	#### $length_i
	#### $j
	#### $length_j
	#
	if ($length_i == 1 && $length_j == 1)
	{
		push @comparators, [$i, $j];
	}
	elsif ($length_i == 1 && $length_j == 2)
	{
		push @comparators, [$i, $j + 1];
		push @comparators, [$i, $j];
	}
	elsif ($length_i == 2 && $length_j == 1)
	{
		push @comparators, [$i, $j];
		push @comparators, [$i + 1, $j];
	}
	else
	{
		my $i_mid = $length_i/2;
		my $j_mid = ($length_i & 1)? $length_j/2: ($length_j + 1)/2;

		push @comparators, bn_merge($i, $i_mid, $j, $j_mid);
		push @comparators, bn_merge($i + $i_mid, $length_i - $i_mid, $j + $j_mid, $length_j - $j_mid);
		push @comparators, bn_merge($i + $i_mid, $length_i - $i_mid, $j, $j_mid);
	}

	#
	### bn_merge() returns
	#### @comparators
	#
	return @comparators;
}

#
# @network = batcher($inputs);
#
# Return a list of two-element lists that comprise the comparators of a
# sorting network.
#
# Batcher's sort as laid out in Knuth, Sorting and Searching, algorithm 5.2.2M.
#
sub batcher
{
	my $inputs = shift;
	my @network;

	#
	# $t = ceiling(log2($inputs)); but we'll
	# find it using the length of the bitstring.
	#
	my $t = unpack("B32", pack("N", $inputs));
	$t =~ s/^0+//;
	$t = length $t;

	my $p = 1 << ($t -1);

	while ($p > 0)
	{
		my $q = 1 << ($t -1);
		my $r = 0;
		my $d = $p;

		while ($d > 0)
		{
			for my $i (0 .. $inputs - $d - 1)
			{
				push @network, [$i, $i + $d] if (($i & $p) == $r);
			}

			$d = $q - $p;
			$q >>= 1;
			$r = $p;
		}
		$p >>= 1;
	}

	return @network;
}



#
# @network = bitonic($inputs);
#
# Return a list of two-element lists that comprise the comparators of a
# sorting network.
#
# Batcher's Bitonic sort as described here:
# http://www.iti.fh-flensburg.de/lang/algorithmen/sortieren/bitonic/oddn.htm
#
sub bitonic
{
	my $inputs = shift;
	my @network;

	my ($sort, $merge);

	$sort = sub {
		my ($lo, $n, $dir) = @_;

		if ($n > 1) {
			my $m = $n/2;
			$sort->($lo, $m, !$dir);
			$sort->($lo + $m, $n - $m, $dir);
			$merge->($lo, $n, $dir);
		}
	};

	$merge = sub {
		my ($lo, $n, $dir) = @_;

		if ($n > 1) {
			#
			# $t = ceiling(log2($n - 1)); but we'll
			# find it using the length of the bitstring.
			#
			my $t = unpack("B32", pack("N", $n - 1));
			$t =~ s/^0+//;
			$t = length $t;

			my $m = 1 << ($t - 1);

			for my $i ($lo .. $lo+$n-$m-1)
			{
				push @network, ($dir)? [$i, $i+$m]: [$i+$m, $i];
			}

			$merge->($lo, $m, $dir);
			$merge->($lo + $m, $n - $m, $dir);
		}
	};

	$sort->(0, $inputs, 1);

	return @{ make_network_unidirectional(\@network) };
}


## This function "re-wires" a bi-directional sorting network
## and turns it into a normal, uni-directional network.

sub make_network_unidirectional
{
	my ($network_ref) = @_;

	my @network = @$network_ref;

	for my $i (0..$#network) {
		my $comparator = $network[$i];
		my ($x, $y) = @$comparator;

		if ($x > $y) {
			for my $j (($i+1)..$#network) {
				my $j_comparator = $network[$j];
				my ($j_x, $j_y) = @$j_comparator;

				$j_comparator->[0] = $y if $x == $j_x;
				$j_comparator->[1] = $y if $x == $j_y;
				$j_comparator->[0] = $x if $y == $j_x;
				$j_comparator->[1] = $x if $y == $j_y;
			}
			($comparator->[0], $comparator->[1]) = ($comparator->[1], $comparator->[0]);
		}
	}

	return \@network;
}

#
# @network = bubble($inputs);
#
# Simple bubble sort network, only for comparison purposes.
#
sub bubble
{
	my $inputs = shift;
	my @network;

	for my $j (reverse 0 .. $inputs - 1)
	{
		push @network, [$_, $_ + 1] for (0 .. $j - 1);
	}

	return @network;
}

#
# @network = bubble($inputs);
#
# Simple odd-even transposition network, only for comparison purposes.
#
sub oddeventransposition
{
	my $inputs = shift;
	my @network;

	my $odd;

	for my $stage (0 .. $inputs - 1)
	{
		for (my $j = $odd ? 1 : 0; $j < $inputs - 1; $j += 2)
		{
			push @network, [$j, $j+1];
		}

		$odd = !$odd;
	}

	return @network;
}

#
# @network = balanced($inputs);
#
# "The Balanced Sorting Network" by M. Dowd, Y. Perl, M Saks, and L. Rudolph
# ftp://ftp.cs.rutgers.edu/cs/pub/technical-reports/pdfs/DCS-TR-127.pdf
#
sub balanced
{
	my $inputs = shift;
	my @network;

	#
	# $t = ceiling(log2($inputs - 1)); but we'll
	# find it using the length of the bitstring.
	#
	my $t = unpack("B32", pack("N", $inputs - 1));
	$t =~ s/^0+//;
	$t = length $t;

	for (1 .. $t)
	{
		for (my $curr = 2**($t); $curr > 1; $curr /= 2)
		{
			for (my $i = 0; $i < 2**$t; $i += $curr)
			{
				for (my $j = 0; $j < $curr/2; $j++)
				{
					my $wire1 = $i+$j;
					my $wire2 = $i+$curr-$j-1;
					push @network, [$wire1, $wire2]
						if $wire1 < $inputs && $wire2 < $inputs;
				}
			}
		}
	}

	return @network;
}

#
# @network = oddevenmerge($inputs);
#
# Batcher's odd-even merge sort as described here:
# http://www.iti.fh-flensburg.de/lang/algorithmen/sortieren/networks/oemen.htm
# http://cs.engr.uky.edu/~lewis/essays/algorithms/sortnets/sort-net.html
#
sub oddevenmerge
{
	my $inputs = shift;
	my @network;

	#
	# $t = ceiling(log2($inputs - 1)); but we'll
	# find it using the length of the bitstring.
	#
	my $t = unpack("B32", pack("N", $inputs - 1));
	$t =~ s/^0+//;
	$t = length $t;

	my ($add_elem, $sort, $merge);

	$add_elem = sub {
		my ($i, $j) = @_;

		push @network, [$i, $j]
			if $i < $inputs && $j < $inputs;
	};

	$sort = sub {
		my ($lo, $n) = @_;

		if ($n > 1)
		{
			my $m = int($n / 2);

			$sort->($lo, $m);
			$sort->($lo + $m, $m);
			$merge->($lo, $n, 1);
		}
	};

	$merge = sub {
		my ($lo, $n, $r) = @_;

		my $m = int($r * 2);

		if ($m < $n)
		{
			$merge->($lo, $n, $m); # even
			$merge->($lo + $r, $n, $m); # odd

			for (my $i=$lo + $r; $i + $r < $lo + $n; $i += $m)
			{
				$add_elem->($i, $i + $r);
			}
		}
		else
		{
			$add_elem->($lo, $lo + $r);
		}
	};

	$sort->(0, 2**$t);

	return @network;
}

#
# $array_ref = $nw->sort(\@array);
#
# Use the network of comparators to sort the elements in the
# array.  Returns the reference to the array, which is sorted
# in-place.
#
# This function is for testing and statistical purposes only, as
# interpreting sorting pairs ad hoc in an interpreted language is
# going to be very slow.
#
=head3 sort()

Sort an array using the network. This is meant for testing purposes
only - looping around an array of comparators in order to sort an
array in an interpreted language is not the most efficient mechanism
for using a sorting network.

This function uses the C<< <=> >> operator for comparisons.

    my @digits = (1, 8, 3, 0, 4, 7, 2, 5, 9, 6);
    my $nw = Algorithm::Networksort->new(
                        inputs => (scalar @digits),
                        algorithm => 'hibbard');
    $nw->sort(\@digits);
    print join(", ", @digits);

=cut

sub sort
{
	my $self = shift;
	my $array  = $_[0];

	my $network = $self->network();

	#
	### sort():
	#### $network
	#### $array
	#

	#
	# Variable $swaps is a global variable that reports back the
	# number of exchanges.
	#
	$swaps = 0;
	for my $comparator (@$network)
	{
		my($left, $right) = @$comparator;

		if (($$array[$left] <=> $$array[$right]) == 1)
		{
			@$array[$left, $right] = @$array[$right, $left];
			$swaps++;
		}

		#
		##### @$array
		#
	}

	return $array;
}

=head3 statistics()

Return statistics on the last sort() call. Currently only "swaps",
a count of the number of exchanges, is returned.

    my(@d, %nw_stats);
    my @digits = (1, 8, 3, 0, 4, 7, 2, 5, 9, 6);
    my $inputs = scalar @digits;
    my $nw_batcher = Algorithm::Networksort->new(inputs => $inputs, algorithm => 'batcher');
    my $nw_bn = Algorithm::Networksort->new(inputs => $inputs, algorithm => 'bosenelson');

    #
    # List will wind up sorted, so copy it for our first test run.
    #
    @d = @digits;
    $nw_batcher->sort(\@d);
    %nw_stats = $nw_batcher->statistics();
    print "The Batcher Merge-Exchange network took ",
        $nw_stats{swaps}, " exchanges to sort the array."

    @d = @digits;
    $nw_bn->sort(\@d);
    %nw_stats = $nw_bn->statistics();
    print "The Bose-Nelson network took ",
        $nw_stats{swaps}, " exchanges to sort the array."

=cut

sub statistics
{
	return (swaps => $swaps,
		);
}

=head2 Methods For Printing

The network object by default prints itself in a grouped format; that is

    my $nw = nwsrt(inputs => 4, algorithm => 'bosenelson');
    print $nw;

Will result in the output

    [[0,1], [2,3],
    [0,2], [1,3],
    [1,2]]

=head3 formats()

An array reference of format strings, for use in formatted printing (see
L<formatted()>).  You may use as many sprintf-style formats as you like
to form your output. 

    $nw->formats([ "swap(%d, %d) ", "if ($card[%d] < $card[%d]);\n" ]);

=head3 index_base()

The values to use to reference array indices in formatted printing (see
L<formatted()>). By default, array indices are zero-based. To use a
different index base (most commonly, one-based array indexing), use
this method.

    $nw->index_base([1 .. $inputs]);

=cut

sub _dflt_formatted
{
	my $self = shift;
	my $network = $_[0];

	#
	# Got comparators?
	#### $network
	#
	if (scalar @$network == 0)
	{
		carp "No network to format.\n";
		return "";
	}

	my $string = "";
	my $index_base = $self->index_base();

	for my $cmptr (@$network)
	{
		@$cmptr = @$index_base[@$cmptr] if (defined $index_base);

		$string .= "[" . join(",", @$cmptr) . "], ";
	}

	chop $string;
	chop $string;

	return $string;
}

#
# _stringify
#
# Show a nicely formatted sorting network.
#
sub _stringify
{
	my $self = shift;
	my @grouped = $self->group();
	my $string = "[";

	for my $grp (@grouped)
	{
		$string .= $self->_dflt_formatted($grp) . "\n";
	}
	substr($string, -1, 1) = ']';    # Overwrite the trailing "\n".
	return $string;
}

=head3 formatted()

    $string = $nw->formatted();

Returns a formatted string that represents the list of comparators.

If no formats have been provided via the L<formats()> method, the default
format will be used: an array of arrays as represented in Perl.

Likewise, the network sorting pairs are zero-based. If you want the
pairs written out for some sequence other than 0, 1, 2, ... then you can
provide that using L<inputs_base()>.

B<Example 0: you want a string in the default format.>

    print $nw->formatted();

B<Example 1: you want the output to look like the default format, but
one-based instead of zero-based.>

    $nw->input_base([1..$inputs]);
    print $nw->formatted();

B<Example 2: you want a simple list of SWAP macros.>

    $nw->formats([ "SWAP(%d, %d);\n" ]);
    print $nw->formatted();

B<Example 3: as with example 2, but the SWAP values need to be one-based instead of zero-based.>

    $nw->input_base([1..$inputs]);
    $nw->formats([ "SWAP(%d, %d);\n" ]);
    print $nw->formatted();

B<Example 4: you want a series of comparison and swap statements.>

    $nw->formats([ "if (v[%d] < v[%d]) then\n",
                "    exchange(v, %d, %d)\nend if\n" ]);
    print $nw->formatted();

B<Example 5: you want the default format to use letters, not numbers.>

    $nw->input_base( [('a'..'z')[0..$inputs]] );
    $nw->formats([ "[%s,%s]," ]);      # Note that we're using the string flag.

    my $string = '[' . $nw->formatted();
    substr($string, -1, 1) = ']';    # Overwrite the trailing comma.

    print $string, "\n";

=cut

sub formatted
{
	my $self = shift;
	my $network = $self->network();

	#
	# Got comparators?
	#### $network
	#
	if (scalar @$network == 0)
	{
		carp "No network to format.\n";
		return "";
	}

	#
	# Got formats?
	#
	my(@formats) = $self->formats? @{ $self->formats() }: ();
	unless (scalar @formats)
	{
		return '[' . $self->_dflt_formatted($network) . ']';
	}

	my $string = '';
	my $index_base = $self->index_base();

	for my $cmptr (@$network)
	{
		@$cmptr = @$index_base[@$cmptr] if (defined $index_base);

		for my $fmt (@formats)
		{
			$string .= sprintf($fmt, @$cmptr);
		}
	}

	return $string;
}

=head3 group()

Takes the comparator list and returns a list of comparator lists, each
sub-list representing a group of comparators that can be operate without
interfering with each other, depending on what is needed for
interference-free grouping.

There is one option available, 'grouping', that will produce a grouping
that represents parallel operations of comparators. Its values may be:

=over 3

=item 'graph'

Group the comnparators as parallel as possible for graphing.

=item 'parallel'

Arrange the sequence in parallel so that it has a minimum depth. This,
after flattening the lists into a single list again, is what is used to
produce the sequence in L<network()>.

=back

The chances that you will need to use this function are slim, but the
following code snippet may represent an example:

    my $nw = Algorithm::Networksort->new(inputs => 8, algorithm => 'batcher');

    print "There are ", $nw->length(),
        " comparators in this network, grouped into\n",
        $nw->depth(), " parallel operations.\n\n";

    print $nw, "\n";

    my @grouped_network = $nw->group(grouping=>'graph');
    print "\nThis will be graphed in ", scalar @grouped_network,
        " columns.\n";

This will produce:

    There are 19 comparators in this network, grouped into 6 parallel operations.

    [[0,4], [1,5], [2,6], [3,7]]
    [[0,2], [1,3], [4,6], [5,7]]
    [[2,4], [3,5], [0,1], [6,7]]
    [[2,3], [4,5]]
    [[1,4], [3,6]]
    [[1,2], [3,4], [5,6]]

    This will be graphed in 11 columns.

=cut

sub group
{
	my $self = shift;
	my $network = $self->comparators;
	my $inputs = $self->inputs;
	my %opts = @_;

	my @node_range_stack;
	my @node_stack;
	my $grp = $opts{grouping} // 'parallel';
 
	#
	# Group the comparator nodes by N.
	#
	if ($grp =~ /^[0-9]+$/)
	{
		my @s = @$network;
		while (scalar @s)
		{
			push @node_stack, [splice(@s, 0, $grp)];
		}
		return @node_stack;
	}

	unless ($grp =~ /^(graph|parallel)$/)
	{
		carp "Unknown option '$grp'";
		return undef;
	}

	#
	# Group the comparator nodes by columns.
	#
	for my $comparator (@$network)
	{
		my($from, $to) = @$comparator;

		#
		# How much of a column becomes untouchable depends upon whether
		# we are trying to print out comparators in a single column, or
		# whether we are just trying to arrange comparators in a single
		# column without concern for overlap.
		#
		my @range = ($grp eq "parallel")?
				($from, $to):
				($from..$to);
		my $col = scalar @node_range_stack;

		#
		# Search back through the stack of columns to see if
		# we can fit the comparator in an existing column.
		#
		while (--$col >= 0)
		{
			last if (grep{$_ != 0} @{$node_range_stack[$col]}[@range]);
		}

		#
		# If even the top column can't fit it in, make a
		# new, empty top.
		#
		if (++$col == scalar(@node_range_stack))
		{
			push @node_range_stack, [(0) x $inputs];
		}

		@{$node_range_stack[$col]}[@range] = (1) x (scalar @range);

		#
		# Autovivification creates the [$col] array element
		# if it doesn't currently exist.
		#
		push @{$node_stack[$col]}, $comparator;
	}

	return @node_stack;
}

#
# Set up the horizontal coordinates.
#
sub hz_coords
{
	my($columns, %grset) = @_;

	my @hcoord = ($grset{hz_margin} + $grset{indent}) x $columns;

	for my $idx (0..$columns-1)
	{
		$hcoord[$idx] += $idx * ($grset{hz_sep} + $grset{stroke_width});
	}

	return @hcoord;
}

#
# Set up the vertical coordinates.
#
sub vt_coords
{
	my($inputs, %grset) = @_;

	my @vcoord = ($grset{vt_margin}) x $inputs;

	for my $idx (0..$inputs-1)
	{
		$vcoord[$idx] += $idx * ($grset{vt_sep} + $grset{stroke_width});
	}

	return @vcoord;
}

=head2 Methods For Graphing

=head3 graph_eps()

Returns a string that graphs out the network's comparators. The format
will be encapsulated postscript.

    my $nw = Algorithm::Networksort(inputs = 4, algorithm => 'bitonic');

    print $nw->graph_eps();

=cut

sub graph_eps
{
	my $self = shift;
	my $network = $self->network();
	my $inputs = $self->inputs();
	my %grset = $self->graphsettings();

	my @node_stack = $self->group(grouping => 'graph');
	my $columns = scalar @node_stack;

	#
	# Set up the vertical and horizontal coordinates.
	#
	my @vcoord = vt_coords($inputs, %grset);
	my @hcoord = hz_coords($columns, %grset);

	my $xbound = $hcoord[$columns - 1] + $grset{hz_margin} + $grset{indent};
	my $ybound = $vcoord[$inputs - 1] + $grset{vt_margin};

	#
	# A long involved piece to create the necessary DSC, the subroutine
	# definitions, arrays of vertical and horizontal coordinates, and
	# left and right margin definitions.
	#
	my $string =
		qq(%!PS-Adobe-3.0 EPSF-3.0\n%%BoundingBox: 0 0 $xbound $ybound\n%%CreationDate: ) .
		localtime() .
		qq(\n%%Creator: ) . $self->creator() .
		qq(\n%%Title: ) . $self->title() .
		qq(\n%%Pages: 1\n%%EndComments\n%%Page: 1 1\n) .
q(
% column inputline1 inputline2 draw-comparatorline
/draw-comparatorline {
    vcoord exch get 3 1 roll vcoord exch get
    3 1 roll hcoord exch get 3 1 roll 2 index exch % x1 y1 x1 y2
    newpath 2 copy currentlinewidth 0 360 arc gsave stroke grestore fill moveto
    2 copy lineto stroke currentlinewidth 0 360 arc gsave stroke grestore fill
} bind def

% inputline draw-inputline
/draw-inputline {
    vcoord exch get leftmargin exch dup rightmargin exch % x1 y1 x2 y1
    newpath 2 copy currentlinewidth 0 360 arc moveto
    2 copy lineto currentlinewidth 0 360 arc stroke
} bind def

) .
		"/vcoord [" .
		join("\n    ", semijoin(' ', 16, @vcoord)) . "] def\n/hcoord [" .
		join("\n    ", semijoin(' ', 16, @hcoord)) . "] def\n\n" .
		"/leftmargin $grset{hz_margin} def\n/rightmargin " .
		($xbound - $grset{hz_margin}) . " def\n\n";

	#
	# Save the current graphics state, then change the default line width,
	# and the drawing coordinates from (0,0) = lower left to an upper left
	# origin.
	#
	$string .= "gsave\n$grset{stroke_width} setlinewidth\n0 $ybound translate\n1 -1 scale\n";

	#
	# Draw the input lines.
	#
	$string .= "\n%\n% Draw the input lines.\n%\n0 1 " . ($inputs-1) . " {draw-inputline} for\n";

	#
	# Draw our comparators.
	# Each member of a group of comparators is drawn in the same column.
	#
	$string .= "\n%\n% Draw the comparator lines.\n%\n";
	my $hidx = 0;
	for my $group (@node_stack)
	{
		for my $comparator (@$group)
		{
			$string .= sprintf("%d %d %d draw-comparatorline\n", $hidx, @$comparator);
		}
		$hidx++;
	}

	$string .= "showpage\ngrestore\n% End of the EPS graph.";
	return $string;
}

#svg.pl --background="#9494A4" --indent=15 --hz_sep=22 --hz_margin=16 --vt_margin=20 --stroke_width=4 --radius=3 --algorithm=bosenelson 4

=head3 graph_svg()

Returns a string that graphs out the network's comparators.

    $nw = Algorithm::Networksort(inputs => 4, algorithm => 'bitonic');
    $svg = $nw->graph_svg();

The output will use the default colors and sizes, and will be enclosed between
E<lt>svgE<gt> and E<lt>/svgE<gt> tags.

An example of using the output in an HTML setting:

    $nw = nwsrt_best(name => 'floyd09');   # See Algorithm::Networksort::Best

    $nw->colorsettings(compbegin => '#04c', compend => '#40c');
    $svg = $nw->graph_svg();

=begin html

<p>Embedded in a web page, this will produce</p>

<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink" width="278" height="154" viewbox="0 0 278 154">
  <defs>
    <g id="I_51b6" style="fill:none; stroke-width:2" >
      <circle style="stroke:black" cx="18" cy="0" r="2" />
      <line style="stroke:black" x1="18" y1="0" x2="260" y2="0" />
      <circle style="stroke:black" cx="260" cy="0" r="2" />
    </g>

    <g id="C1_51b6" style="stroke-width:2" >
      <line style="fill:black; stroke:black" x1="0" y1="0" x2="0" y2="14" />
      <circle style="fill:#04c; stroke:#04c" cx="0" cy="0" r="2" />
      <circle style="fill:#40c; stroke:#40c" cx="0" cy="14" r="2" />
    </g>
    <g id="C3_51b6" style="stroke-width:2" >
      <line style="fill:black; stroke:black" x1="0" y1="0" x2="0" y2="42" />
      <circle style="fill:#04c; stroke:#04c" cx="0" cy="0" r="2" />
      <circle style="fill:#40c; stroke:#40c" cx="0" cy="42" r="2" />
    </g>
    <g id="C2_51b6" style="stroke-width:2" >
      <line style="fill:black; stroke:black" x1="0" y1="0" x2="0" y2="28" />
      <circle style="fill:#04c; stroke:#04c" cx="0" cy="0" r="2" />
      <circle style="fill:#40c; stroke:#40c" cx="0" cy="28" r="2" />
    </g>
    <g id="C4_51b6" style="stroke-width:2" >
      <line style="fill:black; stroke:black" x1="0" y1="0" x2="0" y2="56" />
      <circle style="fill:#04c; stroke:#04c" cx="0" cy="0" r="2" />
      <circle style="fill:#40c; stroke:#40c" cx="0" cy="56" r="2" />
    </g>
  </defs>

  <g id="floyd09_51b6">
    <use xlink:href="#I_51b6" y="21" /> <use xlink:href="#I_51b6" y="35" />
    <use xlink:href="#I_51b6" y="49" /> <use xlink:href="#I_51b6" y="63" />
    <use xlink:href="#I_51b6" y="77" /> <use xlink:href="#I_51b6" y="91" />
    <use xlink:href="#I_51b6" y="105" /> <use xlink:href="#I_51b6" y="119" />
    <use xlink:href="#I_51b6" y="133" />

    <use xlink:href="#C1_51b6" x="27" y="21" /> <use xlink:href="#C1_51b6" x="27" y="63" />
    <use xlink:href="#C1_51b6" x="27" y="105" /> <use xlink:href="#C1_51b6" x="41" y="35" />
    <use xlink:href="#C1_51b6" x="41" y="77" /> <use xlink:href="#C1_51b6" x="41" y="119" />
    <use xlink:href="#C1_51b6" x="55" y="21" /> <use xlink:href="#C1_51b6" x="55" y="63" />
    <use xlink:href="#C1_51b6" x="55" y="105" /> <use xlink:href="#C3_51b6" x="69" y="21" />
    <use xlink:href="#C3_51b6" x="83" y="63" /> <use xlink:href="#C3_51b6" x="97" y="21" />
    <use xlink:href="#C3_51b6" x="111" y="35" /> <use xlink:href="#C3_51b6" x="125" y="77" />
    <use xlink:href="#C3_51b6" x="139" y="35" /> <use xlink:href="#C3_51b6" x="153" y="49" />
    <use xlink:href="#C3_51b6" x="167" y="91" /> <use xlink:href="#C3_51b6" x="181" y="49" />
    <use xlink:href="#C2_51b6" x="195" y="35" /> <use xlink:href="#C2_51b6" x="195" y="91" />
    <use xlink:href="#C4_51b6" x="209" y="49" /> <use xlink:href="#C2_51b6" x="223" y="77" />
    <use xlink:href="#C2_51b6" x="237" y="49" /> <use xlink:href="#C1_51b6" x="237" y="91" />
    <use xlink:href="#C1_51b6" x="251" y="49" />
  </g>
</svg>

=end html

=cut

sub graph_svg
{
	my $self = shift;
	my $network = $self->network();
	my $inputs = $self->inputs();
	my %grset = $self->graphsettings();

	#
	# The 'salt' is used to ensure that the id attributes
	# are unique -- I got bit by this when I put two SVG
	# images in the same page.
	#
	my $salt = "_" . sprintf("%x", int(rand(0x7fff)));

	my @node_stack = $self->group(grouping => 'graph');
	my $columns = scalar @node_stack;

	#
	# Get the colorset, using the foreground color as the default color
	# for drawing.
	#
	my %clrset = map{$_ => ($colorset{$_} // $colorset{foreground} // 'black')} keys %colorset;

	#
	# Set up the vertical and horizontal coordinates.
	#
	my @vcoord = vt_coords($inputs, %grset);
	my @hcoord = hz_coords($columns, %grset);

	my $xbound = $hcoord[$columns - 1] + $grset{hz_margin} + $grset{indent};
	my $ybound = $vcoord[$inputs - 1] + $grset{vt_margin};

	my $right_margin = $hcoord[$columns - 1] + $grset{indent};
	my $radius = $grset{radius};

	my $string = qq(<svg xmlns="http://www.w3.org/2000/svg"\n) .
		qq(     xmlns:xlink="http://www.w3.org/1999/xlink" ) .
		qq(width="$xbound" height="$ybound" viewbox="0 0 $xbound $ybound">\n) .
		qq(  <title>) . $self->title() . qq(</title>\n) .
		qq(  <desc>\n    CreationDate: ) . localtime() .
		qq(\n    Creator: ) . $self->creator() .  qq(\n  </desc>\n);

	#
	# Set a background color by inserting as the first element a <rect>
	# with the full size of the view and a fill of the desired color.
	# Use %colorset instead of %clrset, since we've just torpedoed
	# the background value if it was an undef.
	#
	if (defined $colorset{background})
	{
		my $filler = $colorset{background};
		$string .= qq(  <rect width="100%" height="100%" fill="$filler" />\n);
	}

	#
	# Set up the input line template.
	#
	my $g_style = "style=\"fill:none; stroke-width:$grset{stroke_width}\"";
	my $b_style = "style=\"stroke:$clrset{inputbegin}\"";
	my $l_style = "style=\"stroke:$clrset{inputline}\"";
	my $e_style = "style=\"stroke:$clrset{inputend}\"";

	$string .=
		qq(  <defs>\n) .
		qq(    <!-- Define the input line template. -->\n) .
		qq(    <g id="I$salt" $g_style >\n) .
		qq(      <desc>Input line</desc>\n) .
		qq(      <line $l_style x1="$grset{hz_margin}" y1="0" x2="$right_margin" y2="0" />\n) .
		qq(      <circle $b_style cx="$grset{hz_margin}" cy="0" r="$radius" />\n) .
		qq(      <circle $e_style cx="$right_margin" cy="0" r="$radius" />\n) .
		qq(    </g>\n\n);

	#
	# Set up the comparator templates.
	#
	$string .= qq(    <!-- Define the comparator lines, which vary in length. -->\n);

	$g_style = "style=\"stroke-width:$grset{stroke_width}\"";

	my @cmptr = (0) x $inputs;
	for my $comparator (@$network)
	{
		my($from, $to) = @$comparator;
		my $clen = $to - $from;
		if ($cmptr[$clen] == 0)
		{
			my $endpoint = $vcoord[$to] - $vcoord[$from];
			$cmptr[$clen] = 1;

			#
			# Color the components in the group individually.
			#
			$b_style = "style=\"fill:$clrset{compbegin}; stroke:$clrset{compbegin}\"";
			$l_style = "style=\"fill:$clrset{compline}; stroke:$clrset{compline}\"";
			$e_style = "style=\"fill:$clrset{compend}; stroke:$clrset{compend}\"";

			$string .=
			qq(    <g id="C$clen$salt" $g_style >\n) .
			qq(      <desc>Comparator size $clen</desc>\n) .
			qq(      <line $l_style x1="0" y1="0" x2="0" y2="$endpoint" />\n) .
			qq(      <circle $b_style cx="0" cy="0" r="$radius" />\n) .
			qq(      <circle $e_style cx="0" cy="$endpoint" r="$radius" />\n) .
			qq(    </g>\n);
		}
	}

	$string .= qq(  </defs>\n\n);

	#
	# End of definitions.  Draw the input lines as a group.
	#
	$string .= qq(  <g id=") . $self->nwid() . qq($salt">\n);
	$string .= qq(    <!-- Draw the input lines. -->\n);
	$string .= qq(    <use xlink:href="#I$salt" y="$vcoord[$_]" />\n) for (0..$inputs-1);

	#
	# Draw our comparators.
	# Each member of a group of comparators is drawn in the same column.
	#
	$string .= qq(\n    <!-- Draw the comparator lines. -->\n);
	my $hidx = 0;
	for my $group (@node_stack)
	{
		my $h = $hcoord[$hidx++];

		for my $comparator (@$group)
		{
			my($from, $to) = @$comparator;
			my $clen = $to - $from;
			my $v = $vcoord[$from];

			$string .= qq(    <!-- [$from,$to] -->) .
				qq(<use xlink:href="#C$clen$salt" x="$h" y="$v" />\n);
		}
	}

	$string .= qq(  </g>\n</svg>\n);
	return $string;
}

=head3 graph_text()

Returns a string that graphs out the network's comparators in plain text.

    my $nw = Algorithm::Networksort(inputs = 4, algorithm => 'bitonic');

    print $nw->graph_text();

This will produce

    o--^-----^--^--o
       |     |  |   
    o--v--^--|--v--o
          |  |      
    o--^--v--|--^--o
       |     |  |   
    o--v-----v--v--o


=cut

sub graph_text
{
	my $self = shift;
	my $network = $self->network();
	my $inputs = $self->inputs();
	my %txset = $self->graphsettings();

	my @node_stack = $self->group(grouping => 'graph');
	my @inuse_nodes;

	#
	# Set up a matrix of the begin and end points found in each column.
	# This will tell us where to draw our comparator lines.
	#
	for my $group (@node_stack)
	{
		my @node_column = (0) x $inputs;

		for my $comparator (@$group)
		{
			my($from, $to) = @$comparator;
			@node_column[$from, $to] = (1, -1);
		}
		push @inuse_nodes, [splice @node_column, 0];
	}

	#
	# Print that network.
	#
	my $column = scalar @node_stack;
	my @column_line = (0) x $column;
	my $string = "";

	for my $row (0..$inputs-1)
	{
		#
		# Begin with the input line...
		#
		$string .= $txset{inputbegin};

		for my $col (0..$column-1)
		{
			my @node_column = @{$inuse_nodes[$col]};

			if ($node_column[$row] == 0)
			{
				$string .= $txset{($column_line[$col] == 1)?
					'inputcompline': 'inputline'};
			}
			elsif ($node_column[$row] == 1)
			{
				$string .= $txset{compbegin};
			}
			else
			{
				$string .= $txset{compend};
			}
			$column_line[$col] += $node_column[$row];
		}

		$string .= $txset{inputend};

		#
		# Now print the space in between input lines.
		#
		if ($row != $inputs-1)
		{
			$string .= $txset{gapbegin};

			for my $col (0..$column -1)
			{
				$string .= $txset{($column_line[$col] == 0)?
					'gapnone': 'gapcompline'};
			}

			$string .= $txset{gapend};
		}
	}

	return $string;
}

=head3 colorsettings()

Sets the colors of the graph parts, currently for SVG output only.

The parts are named.

    my %old_colors = $nw->colorsettings(inputbegin => "#c04", inputend => "#c40");

=over 4

=item 'inputbegin'

Opening of input line.

=item 'inputline'

The input line.

=item 'inputend'

Closing of the input line.

=item 'compbegin'

Opening of the comparator.

=item 'compline'

The comparator line.

=item 'compend'

Closing of the comparator line.

=item 'foreground'

Default color for the graph as a whole.

=item 'background'

Color of the background. Currently unimplemented in SVG.

=back

All parts not named are reset to 'undef', and will be colored with the
default 'foreground' color.  The foreground color itself has a default
value of 'black'.  The one exception is the 'background' color, which
has no default color at all.

=cut

sub colorsettings
{
	my $self = shift;
	my %settings = @_;
	my %old_settings;

	return %colorset if (scalar @_ == 0);

	for my $k (keys %settings)
	{
		#
		# If it's a real part to color, save the
		# old value, then set it.
		#
		if (exists $colorset{$k})
		{
			$old_settings{$k} = $colorset{$k};
			$colorset{$k} = $settings{$k};
		}
		else
		{
			carp "colorsettings(): Unknown key '$k'";
		}
	}

	return %old_settings;
}

=head3 graphsettings()

Alter the graphing settings, be it pixel measurements
or ascii-art characters.

    #
    # Set hz_margin, saving its old value for later.
    #
    my %old_gset = $nw->graphsettings(hz_margin => 12);

=head4 Options for graph_svg() and graph_eps():

SVG measurements are in pixels.

=over 3

=item 'hz_margin

I<Default value: 18.>
The horizontal spacing between the edges of the graphic and the
sorting network.

=item 'hz_sep

I<Default value: 12.>
The spacing separating the horizontal lines (the input lines).

=item 'indent'

I<Default value: 9.>
The indention between the start of the input lines and the placement of
the first comparator. The same value spaces the placement of the final
comparator and the end of the input lines.

=item 'radius'

I<Default value: 2.>
Radii of the circles used to end the comparator and input lines.

=item 'stroke_width

I<Default value: 2.>
Width of the lines used to define comparators and input lines.

=item 'vt_margin

I<Default value: 21.>
The vertical spacing between the edges of the graphic and the sorting network.

=item 'vt_sep

I<Default value: 12.>
The spacing separating the vertical lines (the comparators).

=back

=head4 Options for graph_text():

=over 3

=item 'inputbegin'

I<Default value: "o-".>
The starting characters for the input line.

=item 'inputline'

I<Default value: "---".>
The characters that make up an input line.

=item 'inputcompline'

I<Default value: "-|-".>
The characters that make up an input line that has a comparator crossing
over it.

=item 'inputend'

I<Default value: "-o\n".>
The characters that make up the end of an input line.

=item 'compbegin'

I<Default value: "-^-".>
The characters that make up an input line with the starting point of
a comparator.

=item 'compend'

I<Default value: "-v-".>
The characters that make up an input line with the end point of
a comparator.

=item 'gapbegin'

I<Default value: "  " (two spaces).>
The characters that start the gap between the input lines.

=item 'gapcompline'

I<Default value: " | " (space vertical bar space).>
The characters that make up the gap with a comparator passing through.

=item 'gapnone'

I<Default value: "  " (three spaces).>
The characters that make up the space between the input lines.

=item 'gapend'

I<Default value: "  \n" (two spaces and a newline).>
The characters that end the gap between the input lines.

=back

=cut

sub graphsettings
{
	my $self = shift;
	my %settings = @_;
	my %old_settings;

	return %graphset if (scalar @_ == 0);

	for my $k (keys %settings)
	{
		#
		# If it's a real part to graph, save the
		# old value, then set it.
		#
		if (exists $graphset{$k})
		{
			$old_settings{$k} = $graphset{$k};
			$graphset{$k} = $settings{$k};
		}
		else
		{
			carp "graphsettings(): Unknown key '$k'";
		}
	}

	return %old_settings;
}

#
# @newlist = semijoin($expr, $itemcount, @list);
#
# $expr      - A string to be used in a join() call.
# $itemcount - The number of items in a list to be joined.
#              It may be negative.
# @list      - The list
#
# Create a new list by performing a join on I<$itemcount> elements at a
# time on the original list. Any leftover elements from the end of the
# list become the last item of the new list, unless I<$itemcount> is
# negative, in which case the first item of the new list is made from the
# leftover elements from the front of the list.
#
sub semijoin
{
	my($jstr, $itemcount, @oldlist) = @_;
	my(@newlist);

	return @oldlist if ($itemcount <= 1 and $itemcount >= -1);

	if ($itemcount > 0)
	{
		push @newlist, join $jstr, splice(@oldlist, 0, $itemcount)
			while @oldlist;
	}
	else
	{
		$itemcount = -$itemcount;
		unshift @newlist, join $jstr, splice(@oldlist, -$itemcount, $itemcount)
		    while $itemcount <= @oldlist;
		unshift @newlist, join $jstr, splice( @oldlist, 0, $itemcount)
		    if @oldlist;
	}

	return @newlist;
}

1;
__END__

=head1 ACKNOWLEDGMENTS

L<Doug Hoyte|https://github.com/hoytech> provided the code for the bitonic,
odd-even merge, odd-even transposition, balanced, and bubble sort algorithms,
and the idea for what became the L<statistics()> method.

L<Morwenn|https://github.com/Morwenn> found documentation errors and networks
that went into L<Algorithm::Networksort::Best>.

=head1 SEE ALSO

=head2 Bose and Nelson's algorithm.

=over 3

=item

Bose and Nelson, "A Sorting Problem", Journal of the ACM, Vol. 9, 1962, pp. 282-296.

=item

Joseph Celko, "Bose-Nelson Sort", Doctor Dobb's Journal, September 1985.

=item

Frederick Hegeman, "Sorting Networks", The C/C++ User's Journal, February 1993.

=item

Joe Celko, I<Joe Celko's SQL For Smarties> (third edition). Implementing Bose-Nelson sorting network in SQL.

This material isn't in either the second or fourth edition of the book.

=item

Joe Celko, I<Joe Celko's Thinking in Sets: Auxiliary, Temporal, and Virtual Tables in SQL>.

The sorting network material removed from the third edition of I<SQL For Smarties> seems to have been moved to this book.

=back

=head2 Hibbard's algorithm.

=over 3

=item

T. N. Hibbard, "A Simple Sorting Algorithm", Journal of the ACM Vol. 10, 1963, pp. 142-50.

=back

=head2 Batcher's Merge Exchange algorithm.

=over 3

=item

Code for Kenneth Batcher's Merge Exchange algorithm was derived from Knuth's
The Art of Computer Programming, Vol. 3, section 5.2.2.

=back

=head2 Batcher's Bitonic algorithm

=over 3

=item

Kenneth Batcher, "Sorting Networks and their Applications", Proc. of the
AFIPS Spring Joint Computing Conf., Vol. 32, 1968, pp. 307-3114. A PDF of
this article may be found at L<http://www.cs.kent.edu/~batcher/sort.pdf>.

The paper discusses both the Odd-Even Merge algorithm and the Bitonic algorithm.

=item

Dr. Hans Werner Lang has written a detailed discussion of the bitonic
sort algorithm here:
L<http://www.iti.fh-flensburg.de/lang/algorithmen/sortieren/bitonic/bitonicen.htm>

=item

T. H. Cormen, E. E. Leiserson, R. L. Rivest, Introduction to Algorithms,
first edition, McGraw-Hill, 1990, section 28.3.

=item

T. H. Cormen, E. E. Leiserson, R. L. Rivest, C. Stein, Introduction to Algorithms,
2nd edition, McGraw-Hill, 2001, section 27.3.

=back

=head2 Algorithm discussion

=over 3

=item

Donald E. Knuth, The Art of Computer Programming, Vol. 3: (2nd ed.)
Sorting and Searching, Addison Wesley Longman Publishing Co., Inc.,
Redwood City, CA, 1998.

=item

Kenneth Batcher's web site (L<http://www.cs.kent.edu/~batcher/>) lists
his publications, including his paper listed above.

=back

=head1 AUTHOR

John M. Gamble may be found at B<jgamble@cpan.org>

=cut
