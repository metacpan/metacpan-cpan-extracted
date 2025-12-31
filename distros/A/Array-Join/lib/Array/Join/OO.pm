package Array::Join::OO;

use Carp;
use List::MoreUtils qw/uniq/;
use Clone;
use Hash::Merge;

use strict;
use warnings;

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my @arrays = grep { ref $_ eq "ARRAY" } @_;
    croak "This constructor takes exactly two arrays as input" unless scalar @arrays == 2;

    my ($opts) = grep { ref $_ eq "HASH" } @_;

    croak "You must provide an 'on' option of exactly two items" unless ref $opts->{on} eq 'ARRAY' && scalar $opts->{on}->@* == 2;
    
    $opts->{merge} = $opts->{as} || $opts->{merge} || "";
    $opts->{type} //= "inner";

    my @subs = $opts->{on}->@*;
    croak "This constructor takes exactly two subs for key generation" unless scalar @subs == 2;

    my @lookups = map { _make_lookup($arrays[$_], $subs[$_]  ) } (0..$#arrays);
    my @keys = _make_keys(@lookups, $opts);

    bless {
	   arrays  => \@arrays,
	   subs    => \@subs,
	   lookups => \@lookups,
	   keys    => \@keys,
	   opts    => $opts
	  }, $class
}

sub lookups {
    carp "Lookups are not mutable" if scalar @_ > 1;
    return Clone::clone(shift->{lookups});
}

sub keys {
    [ sort shift->{keys}->@* ]
}



sub join {
    my $self = shift;
    my @r;

    my $opts = $self->{opts};

    my ($lookup_a, $lookup_b) = map { Clone::clone($_) } $self->{lookups}->@*;

    my $type = $opts->{type} // "inner";
    my @keys = $self->{keys}->@*;

    for my $k (@keys) {
	if ($type eq "outer")    { $lookup_a->{$k} //= [ -1 ]; $lookup_b->{$k} //= [ -1 ]; }
	elsif ($type eq "left")  { $lookup_b->{$k} //= [ -1 ]; }
	elsif ($type eq "right") { $lookup_a->{$k} //= [ -1 ]; }
	elsif ($type eq "inner") { }
	else { croak sprintf"Unrecognized join type: %s", $type }
    }

    for my $k (@keys) {
	push @r, map { [ $k, $_->@* ] } _cross_product($lookup_a->{$k}, $lookup_b->{$k});
    }

    return
	map { _merge($_->[1], $_->[2], $opts) }
	map {
	[
	 $_->[0],
	 ($_->[1] < 0 ? {} : $self->{arrays}->[0]->[$_->[1]]),
	 ($_->[2] < 0 ? {} : $self->{arrays}->[1]->[$_->[2]])
	]
    } @r;
}

sub _make_lookup {
    my ($array, $sub) = @_;
    my $lookup;
    my $i = 0;
    for ($array->@*) {
	my $k = $sub->($_);
	push $lookup->{$k}->@*, $i;
	$i++;
    }
    return $lookup;
}

sub _make_keys {
    my ($lookup_a, $lookup_b, $opts) = @_;

    my @keys;
    my $type = $opts->{type} // "inner";

    if ($type eq "outer") {
	@keys  = uniq ((CORE::keys $lookup_a->%*), (CORE::keys $lookup_b->%*));
    }
    elsif ($type eq "left") {
	@keys   = CORE::keys $lookup_a->%*;
    }
    elsif ($type eq "right") {
	@keys  = CORE::keys $lookup_b->%*;
    }
    elsif ($type eq "inner") {
	@keys = grep { exists $lookup_a->{$_} } CORE::keys $lookup_b->%*;
    }
    else {
	croak sprintf"Unrecognized join type: %s", $type
    }
    return @keys;
}

sub _cross_product {
    map { my $a = $_; map [ $a, $_ ], $_[1]->@* } $_[0]->@*
}

sub _merge {
    my ($item_a, $item_b, $opts) = @_;

    $item_a = Clone::clone($item_a);
    $item_b = Clone::clone($item_b);

    if (ref $opts->{merge} eq "CODE") {
	return $opts->{merge}->($item_a, $item_b, $opts);
    }
    elsif (ref $opts->{merge} eq "ARRAY") {
	my @names = $opts->{merge}->@*;
	$item_a->{CORE::join ".", $names[0], $_} = delete $item_a->{$_} for CORE::keys $item_a->%*;
	$item_b->{CORE::join ".", $names[1], $_} = delete $item_b->{$_} for CORE::keys $item_b->%*;
	return Hash::Merge::merge($item_a, $item_b);
    }
    elsif ($opts->{merge} && $opts->{merge} =~ /_PRECEDENT$/) {
	local $Hash::Merge::behavior = $opts->{merge};
	return Hash::Merge::merge($item_a, $item_b);	
    }
    elsif ($opts->{merge}) {
	return Hash::Merge::merge($item_a, $item_b);
    }
    else {
	return [ $item_a, $item_b ]
    }
}

1;

=head1 NAME

Array::Join::OO - SQL-like joins over two arrays of hashrefs

=head1 SYNOPSIS

    use Array::Join::OO;

    my $join = Array::Join::OO->new(
        \@left,
        \@right,
        {
            on   => [
                sub { $_[0]{id} },
                sub { $_[0]{id} },
            ],
            type  => 'inner',   # inner | left | right | outer
            merge => 'LEFT_PRECEDENT',
        }
    );

    my @rows = $join->join;

=head1 DESCRIPTION

C<Array::Join::OO> performs SQL-style joins over two Perl arrays.
Each array element is typically a hashref. Join keys are produced
by user-supplied callbacks.

The module supports C<inner>, C<left>, C<right>, and C<outer> joins
and multiple merge strategies for combining matching rows.

Multiple rows per key are supported; all matching combinations
are returned (Cartesian product).

=head1 CONSTRUCTOR

=head2 new( \@array_a, \@array_b, \%options )

Creates a join object.

Exactly two array references must be provided.

The options hash must contain an C<on> key with exactly two
code references, one per array.

=head3 Options

=over 4

=item * on => [ sub {...}, sub {...} ]

Required. Two callbacks that extract a join key from items in
the left and right arrays respectively.

=item * type => 'inner' | 'left' | 'right' | 'outer'

Join type. Defaults to C<inner>.

=item * merge => STR | ARRAY | CODE

Controls how matching rows are combined.

See L</MERGE STRATEGIES>.

=item * as => ...

Alias for C<merge>.

=back

=head1 METHODS

=head2 join

    my @rows = $join->join;

Executes the join and returns a list of merged rows.

For non-inner joins, missing rows are represented as empty hashrefs.

=head2 keys

    my $keys = $join->keys;

Returns a sorted arrayref of join keys used by the join.

=head2 lookups

    my $lookups = $join->lookups;

Returns a deep clone of the internal lookup tables.
This data is read-only.

=head1 MERGE STRATEGIES

The C<merge> option controls how matching rows are combined.

=head2 CODE reference

    merge => sub {
        my ($left, $right, $opts) = @_;
        ...
    }

Receives cloned copies of both rows and must return a single value.

=head2 ARRAY reference

    merge => [ 'left', 'right' ]

All keys in each hash are renamed with the given prefixes
(e.g. C<left.id>, C<right.id>) before merging.

=head2 Hash::Merge behaviors

    merge => 'LEFT_PRECEDENT'
    merge => 'RIGHT_PRECEDENT'
    merge => 'STORAGE_PRECEDENT'

Passed directly to L<Hash::Merge>. If the string ends in
C<_PRECEDENT>, the behavior is applied explicitly.

=head2 Default

If C<merge> is false or omitted, each result row is returned as:

    [ $left_hashref, $right_hashref ]

=head1 JOIN SEMANTICS

=over 4

=item * inner

Only keys present in both arrays.

=item * left

All keys from the left array; missing right rows become empty hashes.

=item * right

All keys from the right array; missing left rows become empty hashes.

=item * outer

All keys from both arrays.

=back

If multiple rows share the same key on either side, all combinations
are returned.

=head1 ERRORS

The constructor throws exceptions if:

=over 4

=item * The wrong number of arrays is provided

=item * The C<on> option is missing or invalid

=item * An unknown join type is specified

=back

=head2 AUTHOR

Simone Cesano <scesano@cpan.org>

=head2 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
