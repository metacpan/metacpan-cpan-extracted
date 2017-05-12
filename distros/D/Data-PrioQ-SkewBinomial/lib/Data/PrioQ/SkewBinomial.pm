package Data::PrioQ::SkewBinomial;

use warnings; no warnings qw(recursion);
use strict;

use constant {
	ELEM => 0,
	OTHERS => 1,
	CHILDREN => 2,
	RANK => 3,

	KEY => 0,
	VALUE => 1,
	HEAP => 2,

	HEAD => 0,
	TAIL => 1,

	NIL => [],
};

BEGIN {
	*VERSION = \'0.03';

	unless (defined &_DEBUG) {
		*_DEBUG = sub () { 0 };
	}
}

sub _confess {
	require Carp;
	{
		no warnings 'redefine';
		*_confess = \&Carp::confess;
	}
	goto &Carp::confess;
}

sub _assert {
	my ($cond, $name) = @_;
	unless ($cond) {
		@_ = "assertion failed: $name";
		goto &_confess;
	}
}

sub _length {
	my ($xs) = @_;
	my $n = 0;
	while (@$xs) {
		$xs = $xs->[TAIL];
		++$n;
	}
	$n
}

sub _strip_rank {
	my ($t) = @_;
	[@$t[ELEM, OTHERS, CHILDREN]]
}

sub _link {
	my ($t1, $t2) = @_;
	_assert $t1->[RANK] == $t2->[RANK], "trees have equal rank" if _DEBUG;

	$t1->[ELEM][KEY] <= $t2->[ELEM][KEY]
		? [$t1->[ELEM], $t1->[OTHERS], [_strip_rank($t2), $t1->[CHILDREN]], $t1->[RANK] + 1]
		: [$t2->[ELEM], $t2->[OTHERS], [_strip_rank($t1), $t2->[CHILDREN]], $t1->[RANK] + 1]
}

sub _skew_link {
	my ($x, $t1, $t2) = @_;
	my $y = _link $t1, $t2;
	_assert _length($y->[OTHERS]) + 1 <= $y->[RANK], "sufficient space in linked tree" if _DEBUG;
	$x->[KEY] <= $y->[ELEM][KEY]
		? [$x, [$y->[ELEM], $y->[OTHERS]], $y->[CHILDREN], $y->[RANK]]
		: [$y->[ELEM], [$x, $y->[OTHERS]], $y->[CHILDREN], $y->[RANK]]
}

sub _insert {
	my ($ts, $x) = @_;
	@$ts && @{$ts->[TAIL]} && $ts->[HEAD][RANK] == $ts->[TAIL][HEAD][RANK]
		? [_skew_link($x, $ts->[HEAD], $ts->[TAIL][HEAD]), $ts->[TAIL][TAIL]]
		: [[$x, NIL, NIL, 0], $ts]
}

sub _ins_tree {
	my ($t, $ts) = @_;
	while (@$ts && $t->[RANK] >= $ts->[HEAD][RANK]) {
		_assert !@{$ts->[TAIL]} || $ts->[HEAD][RANK] < $ts->[TAIL][HEAD][RANK], "tree ranks are strictly increasing" if _DEBUG;
		$t = _link $t, $ts->[HEAD];
		$ts = $ts->[TAIL];
	}
	[$t, $ts]
}

sub _merge_trees {
	my ($ts1, $ts2) = @_;
	@$ts1 or return $ts2;
	@$ts2 or return $ts1;
	my $t1 = $ts1->[HEAD];
	my $t2 = $ts2->[HEAD];
	my $cmp = $t1->[RANK] <=> $t2->[RANK];
	$cmp < 0 ? [$t1, _merge_trees($ts1->[TAIL], $ts2)] :
	$cmp > 0 ? [$t2, _merge_trees($ts1, $ts2->[TAIL])] :
	_ins_tree _link($t1, $t2), _merge_trees($ts1->[TAIL], $ts2->[TAIL])
}

sub _normalize {
	my ($ts) = @_;
	if (@$ts) {
		my $hd = $ts->[HEAD];
		my $tl = $ts->[TAIL];
		@$tl && $hd->[RANK] == $tl->[HEAD][RANK] and return _ins_tree $hd, $tl;
	}
	$ts
}

sub _merge {
	my ($ts1, $ts2) = @_;
	_merge_trees _normalize($ts1), _normalize($ts2)
}

sub _split {
	my ($ts) = @_;
	my $tl = $ts->[TAIL];
	@$tl or return $ts->[HEAD], $tl;
	my $t1 = $ts->[HEAD];
	my ($t2, $ts2) = _split($tl);
	$t1->[ELEM][KEY] <= $t2->[ELEM][KEY]
		? ($ts->[HEAD], $tl)
		: ($t2, [$t1, $ts2])
}

sub _rev_enrank {
	my ($r, $xs) = @_;
	my $ys = NIL;
	while (@$xs) {
		--$r;
		_assert $r >= 0, "rank $r >= 0" if _DEBUG;
		$ys = [[@{$xs->[HEAD]}, $r], $ys];
		$xs = $xs->[TAIL];
	}
	$ys
}

sub _shift_min {
	my ($pq) = @_;
	my ($t, $ts) = _split $pq;
	my $xs = $t->[OTHERS];
	_assert _length($xs) <= $t->[RANK], "not too many extra nodes in min tree" if _DEBUG;
	my $ys = _merge _rev_enrank($t->[RANK], $t->[CHILDREN]), $ts;
	while (@$xs) {
		$ys = _insert $ys, $xs->[HEAD];
		$xs = $xs->[TAIL];
	}
	$ys, $t->[ELEM]
}

sub _bless {
	my ($self, $x) = @_;
	bless $x, ref $self
}

{
	bless \my @e, __PACKAGE__;
	sub empty {
		\@e
	}
}

sub is_empty {
	my $self = shift;
	!@$self
}

sub _singleton {
	my ($self, $k, $v) = @_;
	$self->_bless([$k, $v, NIL])
}

sub insert {
	my ($self, $k, $v) = @_;
	$self->merge($self->_singleton($k, $v))
}

sub merge {
	my ($self, $other) = @_;
	@$self or return $other;
	@$other or return $self;
	my ($min, $max) = $self->[KEY] <= $other->[KEY] ? ($self, $other) : ($other, $self);
	$self->_bless([@$min[KEY, VALUE], _insert $min->[HEAP], $max])
}

sub peek_min {
	my ($self) = @_;
	@$self
		? ($self->[KEY], $self->[VALUE])
		: ()
}

sub _retfst {
	wantarray ? @_ : $_[0]
}

sub shift_min {
	my ($self) = @_;
	@$self or return _retfst $self, undef, undef;
	@{$self->[HEAP]} or return _retfst ref($self)->empty, @$self[KEY, VALUE];
	my ($h, $other) = _shift_min $self->[HEAP];
	_retfst $self->_bless([@$other[KEY, VALUE], _merge $h, $other->[HEAP]]), @$self[KEY, VALUE]
}

1
__END__

=head1 NAME

Data::PrioQ::SkewBinomial - A functional priority queue based on skew binomial trees

=head1 SYNOPSIS

    use aliased 'Data::PrioQ::SkewBinomial' => 'PQ';
    
    my $pq = PQ->empty;
    $pq = $pq->insert(1, "foo")->insert(3, "baz")->insert(2, "bar");
    until ($pq->is_empty) {
        ($pq, my ($priority, $data)) = $pq->shift_min;
        print "$priority: $data\n";
    }

=head1 DESCRIPTION

This module provides a purely functional priority queue. "Purely functional"
means no method ever modifies a queue; instead they all return a new modified
object. There is no real constructor either because there's no need for one: if
the empty queue is never modified, you can just reuse it.

The following methods are available:

=head2 Data::PrioQ::SkewBinomial->empty

I<O(1)>. Returns the empty queue.

=head2 $pq->is_empty

I<O(1)>. Tests whether a priority queue is empty. Returns a boolean value.

=head2 $pq->insert($priority, $item)

I<O(1)>. Returns a new queue containing C<$item> inserted into C<$pq> with a
priority level of C<$priority>. C<$priority> must be a number.

=head2 $pq->merge($pq2)

I<O(1)>. Returns a new queue containing all elements of C<$pq> and C<$pq2>.

=head2 $pq->peek_min

I<O(1)>. Finds the item with the lowest priority value in C<$pq>. Returns
C<($priority, $item)> in list context and C<$item> in scalar context. If
C<$pq> is empty, returns the empty list/undef.

=head2 $pq->shift_min

I<O(log n)>. Finds and removes the item with the lowest priority value in C<$pq>. Returns
C<($pq_, $priority, $item)> in list context and C<$pq_> in scalar context, where
C<$pq_> is a priority queue containing the remaining elements. If C<$pq> is
empty, returns C<($pq, undef, undef)>/C<$pq> in list/scalar context,
respectively.

=head1 AUTHOR

Lukas Mai, C<< <l.mai  at web.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-prioq-skewbinomial at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-PrioQ-SkewBinomial>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::PrioQ::SkewBinomial

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-PrioQ-SkewBinomial>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-PrioQ-SkewBinomial>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-PrioQ-SkewBinomial>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-PrioQ-SkewBinomial>

=back

=head1 ACKNOWLEDGEMENTS

The code in this module is based on: Chris Okasaki, I<Purely Functional Data Structures>.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Lukas Mai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
