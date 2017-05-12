package Algorithm::NeedlemanWunsch;

use warnings;
use strict;

use List::Util qw(max);
use Carp;

our $VERSION = '0.04';

my $from_diag = 1;
my $from_up = 2;
my $from_left = 4;
my $from_diag_idx = 0;
my $from_up_idx = 1;
my $from_left_idx = 2;

sub _curry_callback {
    my ($univ_cb, $spec_name) = @_;

    my $cb;
    if ($spec_name eq 'align') {
        $cb = sub {
	    my $arg = { align => [ @_ ] };
	    my $rv = &$univ_cb($arg);
	    croak "select_align callback returned invalid selection $rv."
	        unless $rv eq 'align';
	};
    } else {
        $cb = sub {
	    my $arg = { $spec_name => $_[0] };
	    my $rv = &$univ_cb($arg);
	    croak "select_align callback returned invalid selection $rv."
	        unless $rv eq $spec_name;
	};
    }

    return $cb;
}

sub _canonicalize_callbacks {
    my $cb;
    if (@_) {
        $cb = $_[0];
    } else {
        $cb = { };
    }

    if (exists($cb->{select_align})) {
        my @cn = qw(align shift_a shift_b);
	foreach (@cn) {
	    if (!exists($cb->{$_})) {
	        $cb->{$_} = _curry_callback($cb->{select_align}, $_);
	    }
	}
    }

    return $cb;
}

sub new {
    my $class = shift;
    my $score_sub = shift;

    my $self = { score_sub => $score_sub, local => 0 };
    if (@_) {
        $self->{gap_penalty} = $_[0];
    }

    return bless $self, $class;
}

sub local {
    my $self = shift;

    if (@_) {
        $self->{local} = $_[0];
    }

    return $self->{local};
}

sub gap_open_penalty {
    my $self = shift;

    if (@_) {
        $self->{gap_open_penalty} = $_[0];
    }

    return $self->{gap_open_penalty};
}

sub gap_extend_penalty {
    my $self = shift;

    if (@_) {
        $self->{gap_extend_penalty} = $_[0];
    }

    return $self->{gap_extend_penalty};
}

sub align {
    my $self = shift;

    my $a = shift;
    my $b = shift;

    $self->{callbacks} = _canonicalize_callbacks(@_);

    if (!exists($self->{gap_open_penalty})) {
	if (exists($self->{gap_extend_penalty})) {
	    croak "gap_open_penalty must be defined together with gap_extend_penalty";
	}

        if (!exists($self->{gap_penalty})) {
	    $self->{gap_penalty} = &{$self->{score_sub}}();
	}

	return $self->_align_basic($a, $b);
    } else {
	if (!exists($self->{gap_extend_penalty})) {
	    croak "gap_extend_penalty must be defined together with gap_open_penalty";
	}

	if ($self->{gap_open_penalty} >= $self->{gap_extend_penalty}) {
	    croak "gap_open_penalty must be smaller than gap_extend_penalty";
	}

	return $self->_align_affine($a, $b);
    }
}

sub _align_basic {
    my $self = shift;
    my $a = shift;
    my $b = shift;

    my $A = [ [ 0 ] ];
    my $D = [ [ 0 ] ];
    my $m = scalar(@$b);
    my $n = scalar(@$a);

    my $score_diag = sub {
        my ($i, $j) = @_;

	$D->[$i - 1]->[$j - 1] +
	    &{$self->{score_sub}}($a->[$j - 1], $b->[$i - 1]);
    };

    my $score_up = sub {
	my ($i, $j) = @_;

	$D->[$i - 1]->[$j] + $self->{gap_penalty};
    };

    my $score_left;
    if (!$self->{local}) {
	$score_left = sub {
	    my ($i, $j) = @_;

	    $D->[$i]->[$j - 1] + $self->{gap_penalty};
	};
    } else {
	$score_left = sub {
	    my ($i, $j) = @_;

	    ($i < $m) ?
		$D->[$i]->[$j - 1] + $self->{gap_penalty} :
		$D->[$i]->[$j - 1];
	};
    }

    # order must correspond to $from_* constants
    my @subproblems = ( $score_diag, $score_up, $score_left );

    my $j = 1;
    while ($j <= $n) {
        $A->[0]->[$j] = $from_left;
	++$j;
    }

    if (!$self->{local}) {
	$j = 1;
	while ($j <= $n) {
	    $D->[0]->[$j] = $j * $self->{gap_penalty};
	    ++$j;
	}
    } else {
        $j = 1;
	while ($j <= $n) {
	    $D->[0]->[$j] = 0;
	    ++$j;
        }
    }

    my $i = 1;
    while ($i <= $m) {
        $A->[$i]->[0] = $from_up;
	++$i;
    }

    $i = 1;
    while ($i <= $m) {
	$D->[$i]->[0] = $i * $self->{gap_penalty};
	++$i;
    }

    $i = 1;
    while ($i <= $m) {
	$j = 1;
	while ($j <= $n) {
	    my @scores = map { &$_($i, $j); } @subproblems;
	    my $d = max(@scores);

	    my $a = 0;
	    my $from = 1;
	    my $k = 0;
	    while ($k < scalar(@scores)) {
		if ($scores[$k] == $d) {
		  $a |= $from;
		}

		$from *= 2;
		++$k;
	    }

	    $A->[$i]->[$j] = $a;
	    $D->[$i]->[$j] = $d;

	    # my $x = join ', ', @scores;
	    # warn "$i, $j: $x -> ", $D->[$i]->[$j], "\n";
	    ++$j;
	}

	++$i;
    }

    $i = $m;
    $j = $n;
    while (($i > 0) || ($j > 0)) {
        my $a = $A->[$i]->[$j];
	my @alt;
	if ($a & $from_diag) {
	    die "internal error" unless ($i > 0) && ($j > 0);
	    push @alt, [ $i - 1, $j - 1 ];
	}

	if ($a & $from_up) {
	    die "internal error" unless ($i > 0);
	    push @alt, [ $i - 1, $j ];
	}

	if ($a & $from_left) {
	    die "internal error" unless ($j > 0);
	    push @alt, [ $i, $j - 1];
	}

	if (!@alt) {
	    die "internal error";
	}

	my $cur = [ $i, $j ];
	my $move;
	if (@alt == 1) {
	    $move = $self->_simple_trace_back($cur, $alt[0],
					      $self->{callbacks});
	} else {
	    $move = $self->_trace_back($cur, \@alt);
	}

	if ($move eq 'align') {
	    --$i;
	    --$j;
	} elsif ($move eq 'shift_a') {
	    --$j;
	} elsif ($move eq 'shift_b') {
	    --$i;
	} else {
	    die "internal error";
	}
    }

    return $D->[$m]->[$n];
}

sub _align_affine {
    my $self = shift;
    my $a = shift;
    my $b = shift;

    my @D = ([ [ 0 ] ], [ [ 0 ] ], [ [ 0 ] ]); # indexed by $from_*_idx
    my $m = scalar(@$b);
    my $n = scalar(@$a);

    my $score_diag = sub {
        my ($i, $j) = @_;

	my @base = map { $_->[$i - 1]->[$j - 1]; } @D;
	my $base = max(@base);
	$base + &{$self->{score_sub}}($a->[$j - 1], $b->[$i - 1]);
    };

    my $score_up = sub {
	my ($i, $j) = @_;

	my @base = map { $_->[$i - 1]->[$j]; } @D;
	$base[$from_diag_idx] += $self->{gap_open_penalty};
	$base[$from_up_idx] += $self->{gap_extend_penalty};
	$base[$from_left_idx] += $self->{gap_open_penalty};
	max(@base);
    };

    my $score_left;
    if (!$self->{local}) {
	$score_left = sub {
	    my ($i, $j) = @_;

	    my @base = map { $_->[$i]->[$j - 1]; } @D;
	    $base[$from_diag_idx] += $self->{gap_open_penalty};
	    $base[$from_up_idx] += $self->{gap_open_penalty};
	    $base[$from_left_idx] += $self->{gap_extend_penalty};

	    max(@base);
	};
    } else {
	$score_left = sub {
	    my ($i, $j) = @_;

	    my @base = map { $_->[$i]->[$j - 1]; } @D;
	    if ($i < $m) {
		$base[$from_diag_idx] += $self->{gap_open_penalty};
		$base[$from_up_idx] += $self->{gap_open_penalty};
		$base[$from_left_idx] += $self->{gap_extend_penalty};
	    }

	    max(@base);
	};
    }

    my $j;
    if (!$self->{local}) {
	$j = 1;
	while ($j <= $n) {
	    foreach (@D) {
		$_->[0]->[$j] = $self->{gap_open_penalty} +
		    ($j - 1) * $self->{gap_extend_penalty};
	    }

	    ++$j;
	}
    } else {
	$j = 1;
	while ($j <= $n) {
	    foreach (@D) {
		$_->[0]->[$j] = 0;
	    }

	    ++$j;
	}
    }

    my $i = 1;
    while ($i <= $m) {
	foreach (@D) {
	    $_->[$i]->[0] = $self->{gap_open_penalty} +
		($i - 1) * $self->{gap_extend_penalty};
	}

	++$i;
    }

    # order must correspond to $from_* constants
    my @subproblems = ( $score_diag, $score_up, $score_left );

    $i = 1;
    while ($i <= $m) {
	$j = 1;
	while ($j <= $n) {
	    my $k = 0;
	    while ($k < 3) { # scalar(@D), scalar(@subproblems)
		$D[$k]->[$i]->[$j] = &{$subproblems[$k]}($i, $j);
		++$k;
	    }

	    # my $x = join ', ', map { $_->[$i]->[$j]; } @D;
	    # warn "$i, $j: $x\n";

	    ++$j;
	}

	++$i;
    }

    # like $score_up
    my @delta_up = ( $self->{gap_open_penalty}, $self->{gap_extend_penalty},
		     $self->{gap_open_penalty} );

    # like $score_left
    my @delta_left = ( $self->{gap_open_penalty}, $self->{gap_open_penalty},
		       $self->{gap_extend_penalty} );

    my @no_delta = (0, 0, 0);

    my @score = map { $_->[$m]->[$n]; } @D;
    my $res = max(@score);

    my $arrow = 0;
    my $flag = 1;
    my $idx = 0;
    while ($idx < 3) { # scalar(@score)
	if ($score[$idx] == $res) {
	    $arrow |= $flag;
	}

	$flag *= 2;
	++$idx;
    }

    $i = $m;
    $j = $n;
    while (($i > 0) || ($j > 0)) {
	my @alt;
	if ($arrow & $from_diag) {
	    die "internal error" unless ($i > 0) && ($j > 0);
	    push @alt, [ $i - 1, $j - 1 ];
	}

	if ($arrow & $from_up) {
	    die "internal error" unless ($i > 0);
	    push @alt, [ $i - 1, $j ];
	}

	if ($arrow & $from_left) {
	    die "internal error" unless ($j > 0);
	    push @alt, [ $i, $j - 1];
	}

	if (!@alt) {
	    die "internal error";
	}

	# my $x = join ', ', map { "[ " . $_->[0] . ", " . $_->[1] . " ]"; } @alt;
	# warn "$i, $j: $x\n";

	my $cur = [ $i, $j ];
	my $move;
	if (@alt == 1) {
	    $move = $self->_simple_trace_back($cur, $alt[0],
					      $self->{callbacks});
	} else {
	    $move = $self->_trace_back($cur, \@alt);
	}

	if ($move eq 'align') {
	    --$i;
	    --$j;

	    @score = map { $_->[$i]->[$j]; } @D;
	    if ($i == 0) {
		$arrow = $from_left;
	    } elsif ($j == 0) {
	        $arrow = $from_up;
	    } else {
		my $d = max(@score);
		$arrow = 0;
		$flag = 1;
		$idx = 0;
		while ($idx < 3) { # scalar(@score)
		    if ($score[$idx] == $d) {
			$arrow |= $flag;
		    }

		    $flag *= 2;
		    ++$idx;
		}
	    }
	} elsif ($move eq 'shift_a') {
	    --$j;

	    my @base = map { $_->[$i]->[$j] } @D;
	    my $delta;
	    if ($self->{local} && ($i == $m)) {
		$delta = \@no_delta;
	    } else {
		$delta = \@delta_left;
	    }

	    $arrow = $self->_retread($score[$from_left_idx],  $i, $j,
                \@base, $delta);
	    @score = @base;
	} elsif ($move eq 'shift_b') {
	    --$i;

	    my @base = map { $_->[$i]->[$j] } @D;
	    $arrow = $self->_retread($score[$from_up_idx], $i, $j,
		\@base, \@delta_up);
	    @score = @base;
	} else {
	    die "internal error";
	}
    }

    return $res;
}

sub _retread {
    my ($self, $to_score, $i, $j, $base, $delta) = @_;

    if ($i == 0) {
	return $from_left;
    } elsif ($j == 0) {
	return $from_up;
    }

    my $a = 0;
    my $flag = 1;
    my $idx = 0;
    while ($idx < 3) {
	if ($base->[$idx] + $delta->[$idx] == $to_score) {
	    $a |= $flag;
	}

	$flag *= 2;
	++$idx;
    }

    return $a;
}

sub _trace_back {
    my ($self, $cur, $sources) = @_;

    my $arg = { };
    foreach my $next (@$sources) {
        my $m = $self->_simple_trace_back($cur, $next, { });
	if ($m eq 'align') {
	    $arg->{align} = [ $cur->[1] - 1, $cur->[0] - 1 ];
	} elsif ($m eq 'shift_a') {
	    $arg->{shift_a} = $cur->[1] - 1;
	} elsif ($m eq 'shift_b') {
	    $arg->{shift_b} = $cur->[0] - 1;
	} else {
	    die "internal error";
	}
    }

    my $move;
    my $cb = $self->{callbacks};
    if (exists($cb->{select_align})) {
        $move = &{$cb->{select_align}}($arg);
	if (!exists($arg->{$move})) {
	    die "select_align callback returned invalid selection $move.";
	}
    } else {
        my @cn = qw(align shift_a shift_b);
	foreach my $m (@cn) {
	    if (exists($arg->{$m})) {
	        $move = $m;
		last;
	    }
	}

	if (!$move) {
	    die "internal error";
	}

	if (exists($cb->{$move})) {
	    if ($move eq 'align') {
	        &{$cb->{align}}(@{$arg->{align}});
	    } else {
	        &{$cb->{$move}}($arg->{$move});
	    }
	}
    }

    return $move;
}

sub _simple_trace_back {
    my ($self, $cur, $next, $cb) = @_;

    if ($next->[0] == $cur->[0] - 1) {
        if ($next->[1] == $cur->[1] - 1) {
	    if (exists($cb->{align})) {
	        &{$cb->{align}}($next->[1], $next->[0]);
	    }

	    return 'align';
	} else {
	    if ($next->[1] != $cur->[1]) {
	        die "internal error";
	    }

	    if (exists($cb->{shift_b})) {
	        &{$cb->{shift_b}}($cur->[0] - 1);
	    }

	    return 'shift_b';
	}
    } else {
        if ($next->[0] != $cur->[0]) {
	    die "internal error";
	}

	if ($next->[1] != $cur->[1] - 1) {
	    die "internal error";
	}

	if (exists($cb->{shift_a})) {
	    &{$cb->{shift_a}}($cur->[1] - 1);
	}

	return 'shift_a';
    }
}

1;

__END__

=head1 NAME

Algorithm::NeedlemanWunsch - sequence alignment with configurable scoring

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

    use Algorithm::NeedlemanWunsch;

    sub score_sub {
        if (!@_) {
	    return -2; # gap penalty
        }

	return ($_[0] eq $_[1]) ? 1 : -1;
    }

    my $matcher = Algorithm::NeedlemanWunsch->new(\&score_sub);
    my $score = $matcher->align(
               \@a,
               \@b,
               {   align     => \&on_align,
                   shift_a => \&on_shift_a,
                   shift_b => \&on_shift_b,
		   select_align => \&on_select_align
               });

=head1 DESCRIPTION

Sequence alignment is a way to find commonalities in two (or more)
similar sequences or strings of some items or characters. Standard
motivating example is the comparison of DNA sequences and their
functional and evolutionary similarities and differences, but the
problem has much wider applicability - for example finding the longest
common subsequence (that is, C<diff>) is a special case of sequence
alignment.

Conceptually, sequence alignment works by scoring all possible
alignments and choosing the alignment with maximal score. For example,
sequences C<a t c t> and C<t g a t> may be aligned

  sequence A: a t c - t
                | |   |
  sequence B: - t g a t

or

  sequence A: - - a t c t
                  | |
  sequence B: t g a t - -

(and exponentially many other ways, of course). Note that
Needleman-Wunsch considers I<global> alignments, over the entire
length of both sequences; each item is either aligned with an item of
the other sequence, or corresponds to a I<gap> (which is always
aligned with an item - aligning two gaps wouldn't help anything). This
approach is especially suitable for comparing sequences of comparable
length and somewhat similar along their whole lengths - that is,
without long stretches that have nothing to do with each other. If
your sequences don't satisfy these requirements, consider using local
alignment, which, strictly speaking, isn't Needleman-Wunsch, but is
similar enough to be implemented in this module as well - see below
for details.

In the example above, the second alignment has more gaps than the
first, but perhaps your a's are structurally important and you like
them lined up so much that you'd still prefer the second
alignment. Conversely, if c is "almost the same" as g, it might be the
first alignment that matches better. Needleman-Wunsch formalizes such
considerations into a I<similarity matrix>, assigning payoffs to each
(ordered, but the matrix is normally symmetrical so that the order
doesn't matter) pair of possible sequence items, plus a I<gap
penalty>, quantifying the desirability of a gap in a sequence. A
preference of pairings over gaps is expressed by a low (relative to
the similarity matrix values, normally negative) gap penalty.

The alignment score is then defined as the sum, over the positions
where at least one sequence has an item, of the similarity matrix
values indexed by the first and second item (when both are defined)
and gap penalties (for items aligned with a gap). For example, if C<S>
is the similarity matrix and C<g> denotes the gap penalty, the
alignment

  sequence A: a a t t c c

  sequence B: a - - - t c

has score C<S[a, a] + 3 * g + S[c, t] + S[c, c]>.

When the gap penalty is 0 and the similarity an identity matrix, i.e.
assigning 1 to every match and 0 to every mismatch, Needleman-Wunsch
reduces to finding the longest common subsequence.

The algorithm for maximizing the score is a standard application of
dynamic programming, computing the optimal alignment score of empty
and 1-item sequences and building it up until the whole input
sequences are taken into consideration. Once the optimal score is
known, the algorithm traces back to find the gap positions. Note that
while the maximal score is obviously unique, the alignment having it
in general isn't; this module's interface allows the calling
application to choose between different optimal alignments.

=head1 METHODS

=head2 Standard algorithm

=head3 new(\&score_sub [, $gap_penalty ])

The constructor. Takes one mandatory argument, which is a coderef to a
sub implementing the similarity matrix, plus an optional gap penalty
argument. If the gap penalty isn't specified as a constructor
argument, the C<Algorithm::NeedlemanWunsch> object gets it by calling
the scoring sub without arguments; apart from that case, the sub is
called with 2 arguments, which are items from the first and second
sequence, respectively, passed to
C<Algorithm::NeedlemanWunsch::align>. Note that the sub must be pure,
i.e. always return the same value when called with the same arguments.

=head3 align(\@a, \@b [, \%callbacks ])

The core of the algorithm. Creates a bottom-up dynamic programming
matrix, fills it with alignment scores and then traces back to find an
optimal alignment, informing the application about its items by
invoking the callbacks passed to the method.

The first 2 arguments of C<align> are array references to the aligned
sequences, the third a hash reference with user-supplied
callbacks. The callbacks are identified by the hash keys, which are as
follows:

=over

=item align

Aligns two sequence items. The callback is called with 2 arguments,
which are the positions of the paired items in C<\@a> and C<\@b>,
respectively.

=item shift_a

Aligns an item of the first sequence with a gap in the second
sequence. The callback is called with 1 argument, which is the
position of the item in C<\@a>.

=item shift_b

Aligns a gap in the first sequence with an item of the second
sequence. The callback is called with 1 argument, which is the
position of the item in C<\@b>.

=item select_align

Called when there's more than one way to construct the optimal
alignment, with 1 argument which is a hashref enumerating the
possibilities. The hash may contain the following keys:

=over

=item align

If this key exists, the optimal alignment may align two sequence
items. The key's value is an arrayref with the positions of the paired
items in C<\@a> and C<\@b>, respectively.

=item shift_a

If this key exists, the optimal alignment may align an item of the
first sequence with a gap in the second sequence. The key's value is
the position of the item in C<\@a>.

=item shift_b

If this key exists, the optimal alignment may align a gap in the first
sequence with an item of the second sequence. The key's value is
the position of the item in C<\@b>.

=back

All keys are optional, but the hash will always have at least one. The
callback must select one of the possibilities by returning one of the
keys.

=back

All callbacks are optional. When there is just one way to make the
optimal alignment, the C<Algorithm::NeedlemanWunsch> object prefers
calling the specific callbacks, but will call C<select_align> if it's
defined and the specific callback isn't.

Note that C<select_align> is called I<instead> of the specific
callbacks, not in addition to them - users defining both
C<select_align> and other callbacks should probably call the specific
callback explicitly from their C<select_align>, once it decides which
one to prefer.

Also note that the passed positions move backwards, from the sequence
ends to zero - if you're building the alignment in your callbacks, add
items to the front.

=head2 Extensions

In addition to the standard Needleman-Wunsch algorithm, this module
also implements two popular extensions: local alignment and affine
block gap penalties. Use of both extensions is controlled by setting
the properties of C<Algorithm::NeedlemanWunsch> object described
below.

=head3 local

When this flag is set before calling
C<Algorithm::NeedlemanWunsch::align>, the alignment scoring doesn't
charge the gap penalty for gaps at the beginning (i.e. before the
first item) and end (after the last item) of the second sequence
passed to C<align>, so that for example the optimal (with identity
matrix as similarity matrix and a negative gap penalty) alignment of
C<a b c d e f g h> and C<b c h> becomes

  sequence A: a b c d e f g h
                | |
  sequence B:   b c h

instead of the global

  sequence A: a b c d e f g h
                | |         |
  sequence B: - b c - - - - h

Note that local alignment is asymmetrical - when using it, the longer
sequence should be the first passed to
C<Algorithm::NeedlemanWunsch::align>.

=head3 gap_open_penalty, gap_extend_penalty

Using the same gap penalty for every gap has the advantage of
simplicity, but some applications may want a more complicated
approach. Biologists, for example, looking for gaps longer than one
DNA sequence base, typically want to distinguish a gap opening
(costly) from more missing items following it (shouldn't cost so
much). That requirement can be modelled by charging 2 gap penalties:
C<gap_open_penalty> for the first gap, and then C<gap_extend_penalty>
for each consecutive gap on the same sequence.

Note that you must set both these properties if you set any of them
and that C<gap_open_penalty> must be less than C<gap_extend_penalty>
(if you know of a use case where the gap opening penalty should be
preferred to gap extension, let me know). With such penalties set
before calling C<Algorithm::NeedlemanWunsch::align>, sequences C<A T G
T A G T G T A T A G T A C A T G C A> and C<A T G T A G T A C A T G C
A> are aligned

  sequence A: A T G T A G T G T A T A G T A C A T G C A
              | | |               | | | | | | | | | | |
  sequence B: A T G - - - - - - - T A G T A C A T G C A

i.e. with all gaps bunched together.

=head1 SEE ALSO

L<Algorithm::Diff>, L<Text::WagnerFischer>

=head1 AUTHOR

Vaclav Barta, C<< <vbar@comp.cz> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-algorithm-needlemanwunsch at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-NeedlemanWunsch>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2013 Vaclav Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

The algorithm is defined by Saul Needleman and Christian Wunsch in "A
general method applicable to the search for similarities in the amino
acid sequence of two proteins", J Mol Biol. 48(3):443-53.

This implementation is based mostly on
L<http://www.ludwig.edu.au/course/lectures2005/Likic.pdf>, local
alignment is from
L<http://www.techfak.uni-bielefeld.de/bcd/Curric/PrwAli/node6.html>.

=cut
