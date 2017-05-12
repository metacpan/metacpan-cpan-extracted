package AlignDB::IntSpan;
use strict;
use warnings;

use Carp;
use Scalar::Util;
use Scalar::Util::Numeric;

use overload (
    q{0+}   => sub { Carp::confess "Can't numerify an AlignDB::IntSpan\n" },
    q{bool} => q{is_not_empty},
    q{""}   => q{as_string},

    # use Perl standard behaviours for other operations
    fallback => 1,
);

our $VERSION = '1.1.1';

my $POS_INF = 2_147_483_647 - 1;             # INT_MAX - 1
my $NEG_INF = ( -2_147_483_647 - 1 ) + 1;    # INT_MIN + 1

sub POS_INF {
    return $POS_INF - 1;
}

sub NEG_INF {
    return $NEG_INF;
}

sub EMPTY_STRING {
    return '-';
}

sub new {
    my $class = shift;
    my $self  = {};
    $self->{edges} = [];
    bless $self, $class;
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

sub clear {
    my $self = shift;
    $self->{edges} = [];
    return $self;
}

sub edges_ref {
    my $self = shift;
    return $self->{edges};
}

sub edges {
    my $self = shift;
    return @{ $self->edges_ref };
}

sub edge_size {
    my $self = shift;
    return scalar $self->edges;
}

sub span_size {
    my $self = shift;
    return $self->edge_size / 2;
}

sub as_string {
    my $self = shift;

    if ( $self->is_empty ) {
        return $self->EMPTY_STRING;
    }

    my @runs;
    my @edges = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
        push @runs, $lower == $upper ? $lower : "$lower-$upper";
    }

    return join( ',', @runs );
}

sub as_array {
    my $self = shift;

    my @elements;
    my @edges = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
        push @elements, ( $lower .. $upper );
    }

    return @elements;
}

sub ranges {
    my $self = shift;

    my @ranges;
    my @edges = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
        push @ranges, ( $lower, $upper );
    }

    return @ranges;
}

sub spans {
    my $self = shift;

    my @spans;
    my @edges = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
        push @spans, [ $lower, $upper ];
    }

    if (@spans) {
        return @spans;
    }
    else {
        return;
    }
}

sub sets {
    my $self = shift;

    my @sets;
    my @edges = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
        push @sets, Scalar::Util::blessed($self)->new("$lower-$upper");
    }

    if (@sets) {
        return @sets;
    }
    else {
        return;
    }
}

sub runlists {
    my $self = shift;

    if ( $self->is_empty ) {
        return $self->EMPTY_STRING;
    }

    my @runlists;
    my @edges = $self->edges;
    while (@edges) {
        my $lower  = shift @edges;
        my $upper  = shift(@edges) - 1;
        my $string = $lower == $upper ? $lower : $lower . '-' . $upper;
        push @runlists, $string;
    }

    if (@runlists) {
        return @runlists;
    }
    else {
        return;
    }
}

sub cardinality {
    my $self = shift;

    my $cardinality = 0;
    my @edges       = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
        $cardinality += $upper - $lower + 1;
    }

    return $cardinality;
}

sub is_empty {
    my $self = shift;
    my $result = $self->edge_size == 0 ? 1 : 0;
    return $result;
}

sub is_not_empty {
    my $self = shift;
    return !$self->is_empty;
}

sub is_neg_inf {
    my $self = shift;
    return $self->edges_ref->[0] == $NEG_INF;
}

sub is_pos_inf {
    my $self = shift;
    return $self->edges_ref->[-1] == $POS_INF;
}

sub is_infinite {
    my $self = shift;
    return $self->is_neg_inf || $self->is_pos_inf;
}

sub is_finite {
    my $self = shift;
    return !$self->is_infinite;
}

sub is_universal {
    my $self = shift;
    return $self->edge_size == 2 && $self->is_neg_inf && $self->is_pos_inf;
}

sub contains_all {
    my $self = shift;

    for my $i (@_) {
        my $pos = $self->_find_pos( $i + 1, 0 );
        return 0 unless $pos & 1;
    }

    return 1;
}

sub contains_any {
    my $self = shift;

    for my $i (@_) {
        my $pos = $self->_find_pos( $i + 1, 0 );
        return 1 if $pos & 1;
    }

    return 0;
}

#@returns AlignDB::IntSpan
sub add_pair {
    my $self   = shift;
    my @ranges = @_;

    if ( scalar(@ranges) != 2 ) {
        Carp::confess "Number of ranges must be two: @ranges\n";
    }

    my $edges_ref = $self->edges_ref;

    my $from = shift @ranges;
    my $to   = shift(@ranges) + 1;
    if ( $from > $to ) {
        Carp::confess "Bad order: $from-$to\n";
    }
    my $from_pos = $self->_find_pos( $from,   0 );
    my $to_pos   = $self->_find_pos( $to + 1, $from_pos );

    if ( $from_pos & 1 ) {
        $from = $edges_ref->[ --$from_pos ];
    }
    if ( $to_pos & 1 ) {
        $to = $edges_ref->[ $to_pos++ ];
    }

    splice @{$edges_ref}, $from_pos, $to_pos - $from_pos, ( $from, $to );

    return $self;
}

#@returns AlignDB::IntSpan
sub add_range {
    my $self   = shift;
    my @ranges = @_;

    if ( scalar(@ranges) % 2 == 1 ) {
        Carp::confess "Number of ranges must be even: @ranges\n";
    }

    while (@ranges) {
        my $from = shift @ranges;
        my $to   = shift @ranges;
        $self->add_pair( $from, $to );
    }

    return $self;
}

#@returns AlignDB::IntSpan
sub add_runlist {
    my $self  = shift;
    my $first = shift;

    $self->add_range( $self->_runlist_to_ranges($first) );

    return $self;
}

#@returns AlignDB::IntSpan
sub add {
    my $self  = shift;
    my $first = shift;

    if ( ref $first eq __PACKAGE__ ) {
        $self->add_range( $first->ranges );
    }
    elsif ( Scalar::Util::Numeric::isint($first) ) {
        if ( scalar @_ > 0 ) {
            $self->add_range( $self->_list_to_ranges( $first, @_ ) );
        }
        else {
            $self->add_pair( $first, $first );
        }
    }
    else {
        $self->add_range( $self->_runlist_to_ranges($first) );
    }

    return $self;
}

#@returns AlignDB::IntSpan
sub invert {
    my $self = shift;

    # $edges_ref is an ArrayRef, which points to the same array as the
    #   'edges' attribute. So manipulate $edges_ref affects the attribute
    my $edges_ref = $self->edges_ref;

    if ( $self->is_empty ) {
        $self->{edges} = [ $NEG_INF, $POS_INF ];    # Universal set
    }
    else {

        # Either add or remove infinity from each end. The net
        # effect is always an even number of additions and deletions
        if ( $edges_ref->[0] == $NEG_INF ) {
            shift @{$edges_ref};
        }
        else {
            unshift @{$edges_ref}, $NEG_INF;
        }

        if ( $edges_ref->[-1] == $POS_INF ) {
            pop @{$edges_ref};
        }
        else {
            push @{$edges_ref}, $POS_INF;
        }
    }

    return $self;
}

#@returns AlignDB::IntSpan
sub remove_range {
    my $self = shift;

    $self->invert;
    $self->add_range(@_);
    $self->invert;

    return $self;
}

#@returns AlignDB::IntSpan
sub remove {
    my $self  = shift;
    my $first = shift;

    if ( ref $first eq __PACKAGE__ ) {
        $self->remove_range( $first->ranges );
    }
    elsif ( Scalar::Util::Numeric::isint($first) ) {
        if ( scalar @_ > 0 ) {
            $self->remove_range( $self->_list_to_ranges( $first, @_ ) );
        }
        else {
            $self->remove_range( $first, $first );
        }
    }
    else {
        $self->remove_range( $self->_runlist_to_ranges($first) );
    }

    return $self;
}

#@returns AlignDB::IntSpan
sub merge {
    my $self = shift;

    for my $supplied (@_) {
        my @ranges = $self->_real_set($supplied)->ranges;
        $self->add_range(@ranges);
    }

    return $self;
}

#@returns AlignDB::IntSpan
sub subtract {
    my $self = shift;
    return $self if $self->is_empty;

    for my $supplied (@_) {
        my @ranges = $self->_real_set($supplied)->ranges;
        $self->remove_range(@ranges);
    }

    return $self;
}

#@returns AlignDB::IntSpan
sub copy {
    my $self = shift;

    my $copy = Scalar::Util::blessed($self)->new;
    $copy->{edges} = [ $self->edges ];

    return $copy;
}

#@returns AlignDB::IntSpan
sub union {
    my $self = shift;

    my $new = $self->copy;
    $new->merge(@_);

    return $new;
}

#@returns AlignDB::IntSpan
sub complement {
    my $self = shift;

    my $new = $self->copy;
    $new->invert;

    return $new;
}

#@returns AlignDB::IntSpan
sub diff {
    my $self = shift;

    return $self if $self->is_empty;

    my $new = $self->copy;
    $new->subtract(@_);

    return $new;
}

#@returns AlignDB::IntSpan
sub intersect {
    my $self = shift;

    return $self if $self->is_empty;

    my $new = $self->complement;
    for my $supplied (@_) {
        my $temp_set = $self->_real_set($supplied)->complement;
        $new->merge($temp_set);
    }
    $new->invert;

    return $new;
}

#@method
#@returns AlignDB::IntSpan
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
    my $member = $index < 0 ? $self->_at_neg( -$index ) : $self->_at_pos($index);
    return $member;
}

sub _at_pos {
    my $self  = shift;
    my $index = shift;

    my $member;
    my $element_before = 0;

    my @edges = $self->edges;
    while (@edges) {
        my $lower     = shift @edges;
        my $upper     = shift(@edges) - 1;
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

    my @r_edges = reverse $self->edges;
    while (@r_edges) {
        my $upper     = shift(@r_edges) - 1;
        my $lower     = shift @r_edges;
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

    my @edges = $self->edges;
    while (@edges) {
        my $lower     = shift @edges;
        my $upper     = shift(@edges) - 1;
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

#@returns AlignDB::IntSpan
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

    #@type AlignDB::IntSpan
    my $slice = Scalar::Util::blessed($self)->new;

    my @edges = $self->edges;

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
    my $sub_set = Scalar::Util::blessed($self)->new(@sub_elements);

    return $sub_set;
}

sub map_set {
    my $self     = shift;
    my $code_ref = shift;

    my @map_elements;
    for ( $self->elements ) {
        for my $element ( $code_ref->() ) {
            if ( defined $element ) {
                push @map_elements, $element;
            }
        }

    }
    my $map_set = Scalar::Util::blessed($self)->new(@map_elements);

    return $map_set;
}

sub substr_span {
    my $self   = shift;
    my $string = shift;

    my $sub_string = "";
    my @spans      = $self->spans;

    for (@spans) {
        my ( $lower, $upper ) = @$_;
        my $length = $upper - $lower + 1;

        $sub_string .= substr( $string, $lower - 1, $length );
    }

    return $sub_string;
}

#@returns AlignDB::IntSpan
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

#@returns AlignDB::IntSpan
sub cover {
    my $self = shift;

    my $cover = Scalar::Util::blessed($self)->new;
    if ( $self->is_not_empty ) {
        $cover->add_pair( $self->min, $self->max );
    }
    return $cover;
}

#@returns AlignDB::IntSpan
sub holes {
    my $self = shift;

    my $holes = Scalar::Util::blessed($self)->new;

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

#@returns AlignDB::IntSpan
sub inset {
    my $self = shift;
    my $n    = shift;

    my $inset = Scalar::Util::blessed($self)->new;
    my @edges = $self->edges;
    while (@edges) {
        my $lower = shift @edges;
        my $upper = shift(@edges) - 1;
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

#@returns AlignDB::IntSpan
sub trim {
    my $self = shift;
    my $n    = shift;
    return $self->inset($n);
}

#@returns AlignDB::IntSpan
sub pad {
    my $self = shift;
    my $n    = shift;
    return $self->inset( -$n );
}

#@returns AlignDB::IntSpan
sub excise {
    my $self      = shift;
    my $minlength = shift;

    my $set = Scalar::Util::blessed($self)->new;
    map { $set->merge($_) } grep { $_->size >= $minlength } $self->sets;

    return $set;
}

#@returns AlignDB::IntSpan
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

#@returns AlignDB::IntSpan
sub find_islands {
    my $self     = shift;
    my $supplied = shift;

    my $island;
    if ( ref $supplied eq __PACKAGE__ ) {
        $island = $self->_find_islands_set($supplied);
    }
    elsif ( Scalar::Util::Numeric::isint($supplied) ) {
        $island = $self->_find_islands_int($supplied);
    }
    else {
        Carp::confess "Don't know how to deal with input to find_island\n";
    }

    return $island;
}

sub _find_islands_int {
    my $self   = shift;
    my $number = shift;

    my $island = Scalar::Util::blessed($self)->new;

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

    my $islands = Scalar::Util::blessed($self)->new;

    if ( $self->overlap($supplied) ) {
        for my $subset ( $self->sets ) {
            $islands->merge($subset) if $subset->overlap($supplied);
        }
    }

    return $islands;
}

#@returns AlignDB::IntSpan
sub nearest_island {
    my $self     = shift;
    my $supplied = shift;

    if ( ref $supplied eq __PACKAGE__ ) {    # just OK
    }
    elsif ( Scalar::Util::Numeric::isint($supplied) ) {
        $supplied = Scalar::Util::blessed($self)->new($supplied);
    }
    else {
        Carp::confess "Don't know how to deal with input to nearest_island\n";
    }

    my $island = Scalar::Util::blessed($self)->new;
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
            Carp::confess "Bad order: $runlist\n" if $1 > $2;
            push @ranges, ( $1, $2 );
        }
        else {
            Carp::confess "Bad syntax: $runlist\n";
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
        return Scalar::Util::blessed($self)->new($supplied);
    }
}

# Return the index of the first element >= the supplied value.
#
# If the supplied value is larger than any element in the list the returned
# value will be equal to the size of the list.
#
# If $pos & 1, i.e. $pos is odd number, $val is in the set
sub _find_pos {
    my $self = shift;
    my $val  = shift;
    my $low  = shift;

    my $edges_ref = $self->edges_ref;
    my $high      = $self->edge_size;

    while ( $low < $high ) {
        my $mid = int( ( $low + $high ) / 2 );
        if ( $val < $edges_ref->[$mid] ) {
            $high = $mid;
        }
        elsif ( $val > $edges_ref->[$mid] ) {
            $low = $mid + 1;
        }
        else {
            return $mid;
        }
    }

    return $low;
}

#----------------------------------------------------------#
# Aliases
#----------------------------------------------------------#

sub runlist      { shift->as_string(@_); }
sub elements     { shift->as_array(@_); }
sub size         { shift->cardinality(@_); }
sub count        { shift->cardinality(@_); }
sub contains     { shift->contains_all(@_); }
sub intersection { shift->intersect(@_); }
sub equals       { shift->equal(@_); }

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::IntSpan - Handling of sets containing integer spans.

=head1 SYNOPSIS

    use AlignDB::IntSpan;

    my $set = AlignDB::IntSpan->new;
    $set->add(1, 2, 3, 5, 7, 9);
    $set->add_range(100, 1_000_000);
    print $set->as_string, "\n";    # 1-3,5,7,9,100-1000000

=head2 Operator overloads

    if ($set) { ... }   # true if $set is not empty

    print "$set\n";     # stringizes to the run list

=head1 DESCRIPTION

The C<AlignDB::IntSpan> module represents sets of integers as a number of
inclusive ranges, for example '1-10,19-23,45-48'. Because many of its
operations involve linear searches of the list of ranges its overall
performance tends to be proportional to the number of distinct ranges. This is
fine for small sets but suffers compared to other possible set representations
(bit vectors, hash keys) when the number of ranges grows large.

This module also represents sets as ranges of values but stores those ranges
in order and uses a binary search for many internal operations so that overall
performance tends towards O log N where N is the number of ranges.

The internal representation used by this module is extremely simple: a set is
represented as a list of integers. Integers in even numbered positions (0, 2,
4 etc) represent the start of a run of numbers while those in odd numbered
positions represent the ends of runs. As an example the set (1, 3-7, 9, 11,
12) would be represented internally as (1, 2, 3, 8, 11, 13).

Sets may be infinite - assuming you're prepared to accept that infinity is
actually no more than a fairly large integer. Specifically the constants
C<$NEG_INF> and C<$POS_INF> are defined to be -(2^31-1) and (2^31-2)
respectively. To create an infinite set invert an empty one:

    my $inf = AlignDB::IntSpan->new->complement;

Sets need only be bounded in one direction - for example this is the set of
all positive integers (assuming you accept the slightly feeble definition of
infinity we're using):

    my $pos_int = AlignDB::IntSpan->new;
    $pos_int->add_range(1, $pos_int->POS_INF);

Many codes come from L<Set::IntSpan>, L<Set::IntSpan::Fast> and
L<Set::IntSpan::Island>.

=head1 METHODS

=head2 B<CONSTANTS>

=head2 POS_INF

Normally used in construction of infinite sets

=head2 NEG_INF

Normally used in construction of infinite sets

=head2 EMPTY_STRING

=head2 B<INTERFACE: Set creation>

=head2 new

    my $set = AlignDB::Intspan->new; # empty set
    my $set = AlignDB::Intspan->new($set_spec); # the content of $set_spec
    my $set = AlignDB::Intspan->new(@set_specs); # the union of @set_specs

Creates and returns an AlignDB::IntSpan object.

=head2 valid

    my $ok = AlignDB::IntSpan->valid($runlist);

Returns true if $runlist is a valid run list.

=head2 clear

    $set->clear;

Clear all contents of $set

=head2 B<INTERFACE: Set contents>

=head2 edges_ref

Return the internal used ArrayRef representing the set.

I don't think you should use this method.

=head2 edges

Return the internal used Array representing the set.

I don't think you should use this method.

=head2 edge_size

Return the number of edges

=head2 span_size

Return the number of spans

=head2 as_string

Return a string representation of the set.

=head2 as_array

Return an array containing all the members of the set in ascending order.

=head2 B<INTERFACE: Span contents>

=head2 ranges

Returns the runs in $set, as a list of ($lower, $upper)

=head2 spans

Returns the runs in $set, as a list of [$lower, $upper]

=head2 sets

Returns the runs in $set, as a list of AlignDB::IntSpan objects. The sets in
the list are in order.

=head2 runlists

Returns the runs in $set, as a list of "$lower-$upper"

=head2 B<INTERFACE: Set cardinality>

=head2 cardinality

Returns the number of elements in $set.

=head2 is_empty

Return true if the set is empty.

=head2 is_not_empty

Return true if the set is not empty.

=head2 is_neg_inf

Return true if the set is negtive infinite.

=head2 is_pos_inf

Return true if the set is positive infinite.

=head2 is_infinite

Return true if the set is infinite.

=head2 is_finite

Return true if the set is finite.

=head2 is_universal

Return true if the set contains all integers.

=head2 B<INTERFACE: Membership test>

=head2 contains_all

Return true if the set contains all of the specified numbers.

=head2 contains_any

Return true if the set contains any of the specified numbers.

=head2 B<INTERFACE: Member operations>

=head2 add_pair

    $set->add_pair($lower, $upper);

Add a pair of inclusive integers to the set.

A pair of arguments constitute a range

=head2 add_range

    $set->add_range($lower, $upper);

Add the inclusive range of integers to the set.

Multiple ranges may be specified. Each pair of arguments constitute a range

=head2 add_runlist

    $set->add_runlist($runlist);

Add the specified runlist to the set.

=head2 add

    $set->add($number1, $number2, $number3 ...)
    $set->add($runlist);

Add the specified integers or a runlist to the set.

=head2 invert

    $set = $set->invert;

Complement the set.

Because our notion of infinity is actually disappointingly finite inverting a
finite set results in another finite set. For example inverting the empty set
makes it contain all the integers between $NEG_INF and $POS_INF inclusive.

As noted above $NEG_INF and $POS_INF are actually just big integers.

=head2 remove_range

$set->remove_range($lower, $upper);

Remove the inclusive range of integers to the set.

Multiple ranges may be specified. Each pair of arguments constitute a range.

=head2 remove

    $set->remove($number1, $number2, $number3 ...);
    $set->remove($runlist);

Remove the specified integers or a runlist to the set.

=head2 merge

    $set->merge($another_set);
    $set->merge($set_spec);

Merge the members of the supplied sets or set_specs into this set.
Any number of sets may be supplied as arguments.

=head2 subtract

    $set->subtract($another_set);
    $set->subtract($set_spec);

Subtract the members of the supplied sets or set_specs out of this set.
Any number of sets may be supplied as arguments.

=head2 B<INTERFACE: Set operations>

=head2 copy

    my $new_set = $set->copy;

Return an identical copy of the set.

=head2 union

Be called either as a method

    my $new_set = $set->union( $other_set );

or as a function:

    my $new_set = AlignDB::IntSpan::union( $set1, $set2, $set3 );

Return a new set that is the union of this set and all of the supplied sets.

=head2 complement

    my $new_set = $set->complement;

Returns a new set that is the complement of this set.

=head2 diff

    my $new_set = $set->diff( $other_set );

Return a set containing all the elements that are in this set but not the
supplied set.

=head2 intersect

Be called either as a method

    my $new_set = $set->intersect( $other_set );

or as a function:

    my $new_set = AlignDB::IntSpan::intersect( $set1, $set2, $set3 );

Return a new set that is the intersection of this set and all the supplied
sets.

=head2 xor

Be called either as a method

    my $new_set = $set->xor( $other_set );

or as a function:

    my $new_set = AlignDB::IntSpan::xor( $set1, $set2, $set3 );

Return a new set that contains all of the members that are in this set or the
supplied set but not both.

Can actually handle more than two setsin which case it returns a set that
contains all the members that are in some of the sets but not all of the sets.

=head2 B<INTERFACE: Set comparison>

=head2 equal

Returns true if $set and $set_spec contain the same elements.

=head2 subset

Returns true if $set is a subset of $set_spec.

=head2 superset

Returns true if $set is a superset of $set_spec.

=head2 smaller_than

Returns true if $set is smaller than $set_spec.

=head2 larger_than

Returns true if $set is larger than $set_spec.

=head2 B<INTERFACE: Indexing>

=head2 at

Returns the indexth element of set, index start from "1".
Negtive indices count backwards from the end of the set.

=head2 index

Returns the index fo a element in the set, index start from "1"

=head2 slice

Give two indexes, return a subset.
These indexes must be positive.

=head2 B<INTERFACE: Extrema>

=head2 min

Returns the smallest element of $set, or undef if there is none.

=head2 max

Returns the largest element of $set, or undef if there is none.

=head2 B<INTERFACE: Utils>

=head2 grep_set

Evaluates the $code_ref for each integer in $set (locally setting $_ to each
integer) and returns an AlignDB::IntSpan object containing those integers for
which the $code_ref returns TRUE.

=head2 map_set

Evaluates the $code_ref for each integer in $set (locally setting $_ to each
integer) and returns an AlignDB::IntSpan object containing all the integers
returned as results of all those evaluations.

Evaluates the $code_ref in list context, so each element of $set may produce
zero, one, or more elements in the returned set. The elements may be returned
in any order, and need not be disjoint.

=head2 substr_span

    my $substring = $set->substr_span($string);

=head2 B<INTERFACE: Spans operations>

=head2 banish_span

=head2 cover

Returns a set consisting of a single span from $set->min to $set->max.

=head2 holes

Returns a set containing all the holes in $set, that is, all the integers that
are in-between spans of $set.

=head2 inset

inset returns a set constructed by removing $n integers from each end of each
span of $set. If $n is negative, then -$n integers are added to each end of
each span.

In the first case, spans may vanish from the set; in the second case, holes
may vanish.

=head2 trim

trim is provided as a synonym for inset.

=head2 pad

pad $set $n is the same as $set->inset( -$n )

=head2 excise

    my $new_set = $set->excise( $minlength )

Removes all spans within $set smaller than $minlength

=head2 fill

    my $new_set = $set->fill( $maxlength )

Fills in all holes in $set smaller than $maxlength

=head2 B<INTERFACE: Inter-set operations>

=head2 overlap

    my $overlap_amount = $set->overlap( $another_set );

Returns the size of intersection of two sets. Equivalent to

    $set->intersect( $another_set )->size;

=head2 distance

    my $distance = $set->distance( $another_set );

Returns the distance between sets, measured as follows.

If the sets overlap, then the distance is negative and given by

    $d = - $set->overlap( $another_set )

If the sets do not overlap, $d is positive and given by the distance on the
integer line between the two closest islands of the sets.

=head2 B<INTERFACE: Islands>

=head2 find_islands

    my $island = $set->find_islands( $integer );
    my $new_set = $set->find_islands( $another_set );

Returns a set containing the island in $set containing $integer.
If $integer is not in $set, an empty set is returned.
Returns a set containing all islands in $set intersecting $another_set.
If $set and $another_set have an empty intersection, an empty set is returned.

=head2 nearest_island

    my $island = $set->nearest_island( $integer );
    my $island = $set->nearest_island( $another_set );

Returns the nearest island(s) in $set that contains, but does not overlap
with, $integer. If $integer lies exactly between two islands, then the
returned set contains these two islands.

Returns the nearest island(s) in $set that intersects, but does not overlap
with, $another_set. If $another_set lies exactly between two islands, then the
returned set contains these two islands.

=head2 at_island

    my $island = $set->at_island( $island_index );

Returns the island indexed by $island_index. Islands are 1-indexed. For a set
with N islands, the first island (ordered left-to-right) has index 1 and the
last island has index N. If $island_index is negative, counting is done back
from the last island (c.f. negative indexes of Perl arrays).

=head2 B<INTERFACE: Aliases>

    runlist         => as_string

    elements        => as_array

    size, count     => cardinality

    contains        => contains_all

    intersection    => intersect

    equals          => equal

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
