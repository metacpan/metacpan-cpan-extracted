package AlignDB::IntSpanXS;
use strict;
use warnings;

use base qw( DynaLoader );
use Carp;
use Scalar::Util qw(blessed);
use Scalar::Util::Numeric qw(isint);

use overload (
    q{0+}   => sub { confess "Can't numerify an AlignDB::IntSpanXS\n" },
    q{bool} => sub { confess "Can't bool an AlignDB::IntSpanXS\n" },
    q{""}   => q{runlist},

    # use Perl standard behaviours for other operations
    fallback => 1,
);

BEGIN {
    our $VERSION = '1.0.3';
    bootstrap AlignDB::IntSpanXS, $VERSION;
}

# POS_INF
# NEG_INF
# EMPTY_STRING

sub new {
    my $class = shift;
    my $self  = _new($class);
    $self->add(@_) if @_ > 0;
    return $self;
}

sub valid {
    my $this    = shift;
    my $runlist = shift;

    my $class = ref($this) || $this;
    my $set = new $class;

    eval { $set->_runlist_to_ranges($runlist) };
    return $@ ? 0 : 1;
}

# clear

sub edges_ref {
    my $self = shift;
    return [ $self->edges ];
}

# edges
# edge_size
# span_size
# as_string
# as_array
# ranges

sub spans {
    my $self = shift;

    my @spans;
    my @ranges = $self->ranges;
    while (@ranges) {
        my $lower = shift @ranges;
        my $upper = shift @ranges;
        push @spans, [ $lower, $upper ];
    }

    return @spans;
}

sub sets {
    my $self = shift;

    my @sets;
    my @ranges = $self->ranges;
    while (@ranges) {
        my $lower = shift @ranges;
        my $upper = shift @ranges;
        push @sets, blessed($self)->new("$lower-$upper");
    }

    return @sets;
}

sub runlists {
    my $self = shift;

    if ( $self->is_empty ) {
        return $self->EMPTY_STRING;
    }

    my @runlists;
    my @ranges = $self->ranges;
    while (@ranges) {
        my $lower  = shift @ranges;
        my $upper  = shift @ranges;
        my $string = $lower == $upper ? $lower : $lower . '-' . $upper;
        push @runlists, $string;
    }

    return @runlists;
}

# cardinality
# is_empty
# is_not_empty
# is_neg_inf
# is_pos_inf
# is_infinite
# is_finite
# is_universal

sub contains_all {
    my $self = shift;

    for my $i (@_) {
        return 0 unless $self->_contains($i);
    }

    return 1;
}

sub contains_any {
    my $self = shift;

    for my $i (@_) {
        return 1 if $self->_contains($i);
    }

    return 0;
}

# add_pair
# add_int
# add_array
# add_runlist

sub add_range {
    my $self   = shift;
    my @ranges = @_;

    if ( scalar(@ranges) % 2 == 1 ) {
        confess "Number of ranges must be even: @ranges\n";
    }

    while (@ranges) {
        my $from = shift @ranges;
        my $to   = shift @ranges;
        $self->add_pair( $from, $to );
    }

    return $self;
}

sub add {
    my $self  = shift;
    my $first = shift;

    if ( ref $first eq __PACKAGE__ ) {
        $self->add_range( $first->ranges );
    }
    elsif ( isint($first) ) {
        if ( scalar @_ > 0 ) {
            $self->add_array( [ $first, @_ ] );
        }
        else {
            $self->add_int($first);
        }
    }
    else {
        $self->add_runlist($first);
    }

    return $self;
}

# invert
# remove_pair
# remove_int
# remove_array
# remove_runlist

sub remove_range {
    my $self = shift;

    $self->invert;
    $self->add_range(@_);
    $self->invert;

    return $self;
}

sub remove {
    my $self  = shift;
    my $first = shift;

    if ( ref $first eq __PACKAGE__ ) {
        $self->remove_range( $first->ranges );
    }
    elsif ( isint($first) ) {
        if ( scalar @_ > 0 ) {
            $self->remove_array( [ $first, @_ ] );
        }
        else {
            $self->remove_int($first);
        }
    }
    else {
        $self->remove_runlist($first);
    }

    return $self;
}

sub merge {
    my $self = shift;

    foreach my $supplied (@_) {
        my @ranges = $self->_real_set($supplied)->ranges;
        $self->add_range(@ranges);
    }

    return $self;
}

sub subtract {
    my $self = shift;

    foreach my $supplied (@_) {
        my @ranges = $self->_real_set($supplied)->ranges;
        $self->remove_range(@ranges);
    }

    return $self;
}

# copy

sub union {
    my $self = shift;

    my $new = $self->copy;
    $new->merge(@_);

    return $new;
}

sub complement {
    my $self = shift;

    my $new = $self->copy;
    $new->invert;

    return $new;
}

sub diff {
    my $self = shift;

    my $new = $self->copy;
    $new->subtract(@_);

    return $new;
}

sub intersect {
    my $self = shift;

    my $new = $self->complement;
    for my $supplied (@_) {
        my $temp_set = $self->_real_set($supplied)->complement;
        $new->merge($temp_set);
    }
    $new->invert;

    return $new;
}

sub xor {
    return intersect( union(@_), intersect(@_)->complement );
}

sub equal {
    my $self = shift;

    for (@_) {
        my $supplied = $self->_real_set($_);

        if ( $self->edge_size != $supplied->edge_size ) {
            return 0;
        }

        my @edges_a = $self->edges;
        my @edges_b = $supplied->edges;

        for ( my $i = 0; $i < $self->edge_size; $i++ ) {
            if ( $edges_a[$i] != $edges_b[$i] ) {
                return 0;
            }
        }
    }

    return 1;
}

sub subset {
    my $self     = shift;
    my $supplied = $self->_real_set(shift);

    return $self->diff($supplied)->is_empty;
}

sub superset {
    my $self     = shift;
    my $supplied = $self->_real_set(shift);

    return $supplied->diff($self)->is_empty;
}

sub smaller_than {
    my $self     = shift;
    my $supplied = shift;

    my $result = $self->subset($supplied) && !$self->equal($supplied);

    return $result ? 1 : 0;
}

sub larger_than {
    my $self     = shift;
    my $supplied = shift;

    my $result = $self->superset($supplied) && !$self->equal($supplied);

    return $result ? 1 : 0;
}

sub at {
    my $self  = shift;
    my $index = shift;
    if ( $index == 0 || abs($index) > $self->cardinality ) {
        return;
    }
    my $member
        = $index < 0 ? $self->_at_neg( -$index ) : $self->_at_pos($index);
    return $member;
}

sub _at_pos {
    my $self  = shift;
    my $index = shift;

    my $member;
    my $element_before = 0;

    my @ranges = $self->ranges;
    while (@ranges) {
        my $lower     = shift @ranges;
        my $upper     = shift @ranges;
        my $span_size = $upper - $lower + 1;

        if ( $index > $element_before + $span_size ) {
            $element_before += $span_size;
        }
        else {
            $member = $index - $element_before - 1 + $lower;
            last;
        }
    }

    return $member;
}

sub _at_neg {
    my $self  = shift;
    my $index = shift;

    my $member;
    my $element_after = 0;

    my @r_ranges = reverse $self->ranges;
    while (@r_ranges) {
        my $upper     = shift @r_ranges;
        my $lower     = shift @r_ranges;
        my $span_size = $upper - $lower + 1;

        if ( $index > $element_after + $span_size ) {
            $element_after += $span_size;
        }
        else {
            $member = $upper - ( $index - $element_after ) + 1;
            last;
        }
    }

    return $member;
}

sub index {
    my $self   = shift;
    my $member = shift;

    my $index;
    my $element_before = 0;

    my @ranges = $self->ranges;
    while (@ranges) {
        my $lower     = shift @ranges;
        my $upper     = shift @ranges;
        my $span_size = $upper - $lower + 1;

        if ( $member >= $lower and $member <= $upper ) {
            $index = $member - $lower + 1 + $element_before;
            last;
        }
        else {
            $element_before += $span_size;
        }
    }

    return $index;
}

sub slice {
    my $self = shift;
    my $from = shift;
    my $to   = shift;

    if ( $from < 1 ) {
        carp "Start index less than 1\n";
        $from = 1;
    }
    my $slice = $self->_splice( $from, $to - $from + 1 );

    return $slice;
}

sub _splice {
    my $self   = shift;
    my $offset = shift;
    my $length = shift;

    my @edges = $self->edges;
    my $slice = blessed($self)->new;

    while ( @edges > 1 ) {
        my ( $lower, $upper ) = @edges[ 0, 1 ];
        my $span_size = $upper - $lower;

        if ( $offset <= $span_size ) {
            last;
        }
        else {
            splice( @edges, 0, 2 );
            $offset -= $span_size;
        }
    }

    @edges
        or return $slice;    # empty set

    $edges[0] += $offset - 1;

    my @slices = $self->_splice_length( \@edges, $length );
    while (@slices) {
        my $lower = shift @slices;
        my $upper = shift(@slices) - 1;
        $slice->add_pair( $lower, $upper );
    }

    return $slice;
}

sub _splice_length {
    my $self      = shift;
    my $edges_ref = shift;
    my $length    = shift;

    if ( !defined $length ) {
        return @{$edges_ref};    # everything
    }

    if ( $length <= 0 ) {
        return ();               # empty
    }

    my @slices;

    while ( @$edges_ref > 1 ) {
        my ( $lower, $upper ) = @$edges_ref[ 0, 1 ];
        my $span_size = $upper - $lower;

        if ( $length <= $span_size ) {
            last;
        }
        else {
            push @slices, splice( @$edges_ref, 0, 2 );
            $length -= $span_size;
        }
    }

    if (@$edges_ref) {
        my $lower = shift @$edges_ref;
        push @slices, $lower, $lower + $length;
    }

    return @slices;
}

sub min {
    my $self = shift;

    if ( $self->is_empty ) {
        return;
    }
    else {
        return $self->edges_ref->[0];
    }
}

sub max {
    my $self = shift;

    if ( $self->is_empty ) {
        return;
    }
    else {
        return $self->edges_ref->[-1] - 1;
    }
}

sub grep_set {
    my $self     = shift;
    my $code_ref = shift;

    my @sub_elements;
    for ( $self->elements ) {
        if ( $code_ref->() ) {
            push @sub_elements, $_;
        }

    }
    my $sub_set = blessed($self)->new(@sub_elements);

    return $sub_set;
}

sub map_set {
    my $self     = shift;
    my $code_ref = shift;

    my @map_elements;
    for ( $self->elements ) {
        foreach my $element ( $code_ref->() ) {
            if ( defined $element ) {
                push @map_elements, $element;
            }
        }

    }
    my $map_set = blessed($self)->new(@map_elements);

    return $map_set;
}

sub substr_span {
    my $self   = shift;
    my $string = shift;

    my $sub_string = "";
    my @spans      = $self->spans;

    foreach (@spans) {
        my ( $lower, $upper ) = @$_;
        my $length = $upper - $lower + 1;

        $sub_string .= substr( $string, $lower - 1, $length );
    }

    return $sub_string;
}

sub banish_span {
    my $self  = shift;
    my $start = shift;
    my $end   = shift;

    my $remove_length = $end - $start + 1;

    my $new = $self->map_set(
        sub {
                  $_ < $start ? $_
                : $_ > $end   ? $_ - $remove_length
                :               ();
        }
    );

    return $new;
}

sub cover {
    my $self = shift;

    my $cover = blessed($self)->new;
    if ( $self->is_not_empty ) {
        $cover->add_pair( $self->min, $self->max );
    }
    return $cover;
}

sub holes {
    my $self = shift;

    my $holes = blessed($self)->new;

    if ( $self->is_empty or $self->is_universal ) {

        # empty set and universal set have no holes
    }
    else {
        my $c_set  = $self->complement;
        my @ranges = $c_set->ranges;

        # Remove infinite arms of complement set
        if ( $c_set->is_neg_inf ) {

            shift @ranges;
            shift @ranges;
        }
        if ( $c_set->is_pos_inf ) {
            pop @ranges;
            pop @ranges;
        }
        $holes->add_range(@ranges);
    }

    return $holes;
}

sub inset {
    my $self = shift;
    my $n    = shift;

    my $inset  = blessed($self)->new;
    my @ranges = $self->ranges;
    while (@ranges) {
        my $lower = shift @ranges;
        my $upper = shift @ranges;
        if ( $lower != $self->NEG_INF ) {
            $lower += $n;
        }
        if ( $upper != $self->POS_INF ) {
            $upper -= $n;
        }
        $inset->add_pair( $lower, $upper )
            if $lower <= $upper;
    }

    return $inset;
}

sub trim {
    my $self = shift;
    my $n    = shift;
    return $self->inset($n);
}

sub pad {
    my $self = shift;
    my $n    = shift;
    return $self->inset( -$n );
}

sub excise {
    my $self      = shift;
    my $minlength = shift;

    my $set = blessed($self)->new;
    map { $set->merge($_) } grep { $_->size >= $minlength } $self->sets;

    return $set;
}

sub fill {
    my $self      = shift;
    my $maxlength = shift;

    my $set = $self->copy;
    if ( $maxlength > 0 ) {
        for my $hole ( $set->holes->sets ) {
            if ( $hole->size <= $maxlength ) {
                $set->merge($hole);
            }
        }
    }
    return $set;
}

sub overlap {
    my $self     = shift;
    my $supplied = shift;
    return $self->intersect($supplied)->size;
}

sub distance {
    my $self     = shift;
    my $supplied = shift;

    return unless $self->size and $supplied->size;

    my $overlap = $self->overlap($supplied);
    return -$overlap if $overlap;

    my $min_d;
    for my $span1 ( $self->sets ) {
        for my $span2 ( $supplied->sets ) {
            my $d1 = abs( $span1->min - $span2->max );
            my $d2 = abs( $span1->max - $span2->min );
            my $d  = $d1 < $d2 ? $d1 : $d2;
            if ( !defined $min_d or $d < $min_d ) {
                $min_d = $d;
            }
        }
    }

    return $min_d;
}

sub find_islands {
    my $self     = shift;
    my $supplied = shift;

    my $island;
    if ( ref $supplied eq __PACKAGE__ ) {
        $island = $self->_find_islands_set($supplied);
    }
    elsif ( isint($supplied) ) {
        $island = $self->_find_islands_int($supplied);
    }
    else {
        confess "Don't know how to deal with input to find_island\n";
    }

    return $island;
}

sub _find_islands_int {
    my $self   = shift;
    my $number = shift;

    my $island = blessed($self)->new;

    # if $pos & 1, i.e. $pos is odd number, $val is in the set
    my $pos = $self->_find_pos( $number + 1, 0 );
    if ( $pos & 1 ) {
        my @ranges = $self->ranges;
        $island->add_range( $ranges[ $pos - 1 ], $ranges[$pos] );
    }

    return $island;
}

sub _find_islands_set {
    my $self     = shift;
    my $supplied = shift;

    my $islands = blessed($self)->new;

    if ( $self->overlap($supplied) ) {
        for my $subset ( $self->sets ) {
            $islands->merge($subset) if $subset->overlap($supplied);
        }
    }

    return $islands;
}

sub nearest_island {
    my $self     = shift;
    my $supplied = shift;

    if ( ref $supplied eq __PACKAGE__ ) {    # just OK
    }
    elsif ( isint($supplied) ) {
        $supplied = blessed($self)->new($supplied);
    }
    else {
        confess "Don't know how to deal with input to nearest_island\n";
    }

    my $island = blessed($self)->new;
    my $min_d;
    for my $s ( $self->sets ) {
        for my $ss ( $supplied->sets ) {
            next if $s->overlap($ss);
            my $d = $s->distance($ss);
            if ( !defined $min_d or $d <= $min_d ) {
                if ( defined $min_d and $d == $min_d ) {
                    $island->merge($s);
                }
                else {
                    $min_d  = $d;
                    $island = $s->copy;
                }
            }
        }
    }

    return $island;
}

sub at_island {
    my $self  = shift;
    my $index = shift;

    return if $index == 0 or abs($index) > $self->span_size;

    my @islands = $self->sets;

    return $index < 0 ? $islands[$index] : $islands[ $index - 1 ];
}

#----------------------------------------------------------#
# Internal methods
#----------------------------------------------------------#
# Converts a list of integers into pairs of ranges
sub _list_to_ranges {
    my $self = shift;

    my @list = sort { $a <=> $b } @_;
    my @ranges;
    my $count = scalar @list;
    my $pos   = 0;
    while ( $pos < $count ) {
        my $end = $pos + 1;
        $end++ while $end < $count && $list[$end] <= $list[ $end - 1 ] + 1;
        push @ranges, ( $list[$pos], $list[ $end - 1 ] );
        $pos = $end;
    }

    return @ranges;
}

# Converts a runlist into pairs of ranges
sub _runlist_to_ranges {
    my $self = shift;

    my $runlist = shift;
    $runlist =~ s/\s|_//g;
    return if $runlist eq $self->EMPTY_STRING;

    my @ranges;

    for my $run ( split ",", $runlist ) {
        if ( $run =~ /^ (-?\d+) $/x ) {
            push @ranges, ( $1, $1 );
        }
        elsif ( $run =~ /^ (-?\d+) - (-?\d+) $/x ) {
            confess "Bad order: $runlist\n" if $1 > $2;
            push @ranges, ( $1, $2 );
        }
        else {
            confess "Bad syntax: $runlist\n";
        }
    }

    return @ranges;
}

# Converts a set specification into a set
sub _real_set {
    my $self     = shift;
    my $supplied = shift;

    if ( defined $supplied and ref $supplied eq __PACKAGE__ ) {
        return $supplied;
    }
    else {
        return blessed($self)->new($supplied);
    }
}

# _find_pos

#----------------------------------------------------------#
# Aliases
#----------------------------------------------------------#

sub runlist      { shift->as_string; }
sub run_list     { shift->as_string; }
sub elements     { shift->as_array; }
sub size         { shift->cardinality; }
sub count        { shift->cardinality; }
sub empty        { shift->is_empty; }
sub contains     { shift->contains_all(@_); }
sub contain      { shift->contains_all(@_); }
sub member       { shift->contains_all(@_); }
sub duplicate    { shift->copy; }
sub intersection { shift->intersect(@_); }
sub equals       { shift->equal(@_); }
sub join_span    { shift->fill(@_); }

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::IntSpanXS - XS version of AlignDB::IntSpan.

=head1 SYNOPSIS

    use AlignDB::IntSpanXS;

    my $set = AlignDB::IntSpanXS->new;
    $set->add(1, 2, 3, 5, 7, 9);
    $set->add_range(100, 1_000_000);
    print $set->as_string, "\n";    # 1-3,5,7,9,100-1000000

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
