package Array::Join;

# ABSTRACT: performs SQL-like joins on arrays

use v5.20;                          # Require at least Perl 5.20
no warnings 'experimental::signatures';   # Silence “experimental” warnings
use feature 'signatures';           # Turn on the feature
use strict;
use warnings;

use Carp;
use List::MoreUtils qw/uniq/;
use Hash::Merge;
use parent 'Exporter';  # inherit all of Exporter's methods

our @EXPORT = qw(join_arrays);

sub join_arrays {
    my ($arr_a, $arr_b, $sub_a, $sub_b, $opts) = @_;
    $opts //= {};

    my $lookup_a = make_lookup($arr_a, $sub_a);
    my $lookup_b = make_lookup($arr_b, $sub_b);

    my @res = make_joined($arr_a, $arr_b, $lookup_a, $lookup_b, $opts);
    @res = flatten_result(\@res, $opts);
    return @res;
}

sub flatten_result {
    my ($joined, $opts) = @_;
    if (ref $opts->{merge} eq "CODE") {
	return $opts->{merge}->($_->@*);
    }
    elsif (ref $opts->{merge} eq "ARRAY") {
	my @names = $opts->{merge}->@*;
	return map {
	    my $r = $_;
	    Hash::Merge::merge(
			       { map { (join ".", $names[0], $_) => $r->[0]{$_} } keys %{ $r->[0] } },
			       { map { (join ".", $names[1], $_) => $r->[1]{$_} } keys %{ $r->[1] } }
			      )
	} $joined->@*;
	return $joined->@*;
    }
    elsif ($opts->{merge} && $opts->{merge} =~ /_PRECEDENT$/) {
	Hash::Merge::set_behavior($opts->{merge});
	return map { Hash::Merge::merge $_->[0], $_->[1] } $joined->@*
    }
    elsif ($opts->{merge}) {
	return map { Hash::Merge::merge $_->[0], $_->[1] } $joined->@*
    }
    return $joined->@*;
}

sub make_joined  {
    my ($arr_a, $arr_b, $lookup_a, $lookup_b, $opts) = @_;
    my @keys = make_keys($lookup_a, $lookup_b, $opts);

    my @res;
    for (@keys) {
	my @cross = cross_product($lookup_a->{$_}, $lookup_b->{$_});
	for (@cross) {
	    push @res,
		[
		 $arr_a->[$_->[0]],
		 $arr_b->[$_->[1]],
		]
	    }
    }
    return @res;
}

sub make_keys {
    my ($lookup_a, $lookup_b, $opts) = @_;

    my @keys;
    if ($opts->{type} eq "outer") {
	@keys  = uniq ((keys $lookup_a->%*), (keys $lookup_b->%*));
    }
    elsif ($opts->{type} eq "left") {
	@keys   = keys $lookup_a->%*;
    }
    elsif ($opts->{type} eq "right") {
	@keys  = keys $lookup_b->%*;
    }
    elsif (!defined $opts->{type} || $opts->{type} eq "inner") {
	@keys = grep { exists $lookup_a->{$_} } keys $lookup_b->%*;
    }
    else {
	croak sprintf"Unrecognized join type: %s", $opts->{type}
    }
    return @keys;
}

sub make_lookup {
    my ($array, $sub) = @_;
    my $lookup;
    for (0..$#$array) {
	my $k = $sub->($array->[$_]);
	$lookup->{$k} = [] unless $lookup->{$k};
	push $lookup->{$k}->@*, $_;
    }
    return $lookup
}

sub cross_product {
    map { my $a = $_; map [ $a, $_ ], $_[1]->@* } $_[0]->@*
}

1;

=encoding UTF-8

=pod

=head1 NAME

Array::Join - performs SQL-like joins on arrays

=head1 SYNOPSIS

    use Array::Join;

    my @arr_a = (
        { id => 1, name => 'Alice' },
        { id => 2, name => 'Bob' },
    );

    my @arr_b = (
        { uid => 1, email => 'alice@example.com' },
        { uid => 3, email => 'carol@example.com' },
    );

    my @joined = join_arrays(
        \@arr_a,
        \@arr_b,
        sub { $_->{id} },
        sub { $_->{uid} },
        {
            type  => 'left',
            merge => [ 'a', 'b' ],
        }
    );

    # Result:
    # (
    #   { 'a.id' => 1, 'a.name' => 'Alice', 'b.uid' => 1, 'b.email' => 'alice@example.com' },
    #   { 'a.id' => 2, 'a.name' => 'Bob' },  # No match in B
    # )

=head1 DESCRIPTION

C<Array::Join> provides SQL-style joining functionality on arrayrefs of hashrefs.

It supports the four common SQL join types (inner, left, right, outer) and provides
options to control merging behavior.

=head1 FUNCTIONS

=head2 join_arrays

    @result = join_arrays($arr_a, $arr_b, $key_sub_a, $key_sub_b, \%opts);

Performs a join between two arrayrefs of hashrefs, using two key extractor functions.
Returns a list of joined results.

=over 4

=item * C<$arr_a>, C<$arr_b>

Arrayrefs of hashrefs to join.

=item * C<$key_sub_a>, C<$key_sub_b>

Code references that return the join key for a given item in the array.

    sub { $_->{foo} }

=item * C<\%opts> (optional)

A hashref of options to configure the join behavior.

=back

=head3 Options

=over 4

=item * C<type>

The type of join to perform. One of:

=over 4

=item C<'inner'> (default)

Return only matching pairs (intersection of keys in both inputs).

=item C<'left'>

Include all entries from the left side, and matching entries from the right side if any.

=item C<'right'>

Include all entries from the right side, and matching entries from the left side if any.

=item C<'outer'>

Include all keys present in either array (full outer join). Rows without matches are joined with C<undef>.

=back

=item * C<merge>

Controls how the matched pairs are flattened into a single hash per output row.

This can be:

=over 4

=item A CODEREF

A sub that receives two hashrefs (left and right item) and returns a merged hashref.

    merge => sub {
        my ($left, $right) = @_;
        return { %$left, %$right };
    }

=item An ARRAYREF

An arrayref of two prefix strings to apply to the keys of each side. For example:

    merge => [ 'left', 'right' ]

Would turn:

    { name => 'Alice' } and { email => 'a@example.com' }

into:

    { 'left.name' => 'Alice', 'right.email' => 'a@example.com' }

=item C<'LEFT_PRECEDENT'> or C<'RIGHT_PRECEDENT'> or other L<Hash::Merge> behaviors

These use the L<Hash::Merge> behaviors to merge the hashes. For example:

    merge => 'LEFT_PRECEDENT'

will favor keys from the left hashref when they conflict.

=item C<true value>

Any other true value will merge using Hash::Merge’s default behavior.

=item C<false/undef>

If C<merge> is not provided or false, the result will be a list of arrayrefs with two elements (left, right). For example:

    [ $item_from_a, $item_from_b ]

=back

=back

=head1 INTERNAL FUNCTIONS

These are not exported.

=head2 make_lookup($arrayref, $key_sub)

Creates a hashref mapping keys to arrayrefs of array indexes for faster lookup.

=head2 make_keys($lookup_a, $lookup_b, \%opts)

Generates the list of join keys to consider, depending on join type.

=head2 make_joined(...)

Assembles the actual matching row pairs based on the join keys.

=head2 flatten_result($arrayref_of_pairs, \%opts)

Converts pairs of hashrefs into merged single hashes, based on C<merge> option.

=head2 cross_product($listref1, $listref2)

Creates the full cross-product (i.e., every combination of pairings) between two lists of indexes.

=head1 EXPORTS

Only one function is exported by default:

=over 4

=item * C<join_arrays>

=back

=head1 CAVEATS

This was built for convenience, not performance. It's never been tested for very large arrays

=head1 TODO

=over 4

=item * Test comparing behaviour with SQL

=item * More tests

=item * Joining more than 2 arrays

=back

=head1 SEE ALSO

L<Hash::Merge>

=head2 AUTHOR

Simone Cesano <scesano@cpan.org>

=head2 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
