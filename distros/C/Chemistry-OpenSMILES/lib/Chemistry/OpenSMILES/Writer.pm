package Chemistry::OpenSMILES::Writer;

# ABSTRACT: OpenSMILES format writer
our $VERSION = '0.10.0'; # VERSION

use strict;
use warnings;

use Chemistry::OpenSMILES qw(
    %bond_symbol_to_order
    %normal_valence
    is_aromatic
    is_chiral
    toggle_cistrans
    valence
);
use Chemistry::OpenSMILES::Parser;
use Chemistry::OpenSMILES::Stereo::Tables qw( @OH @TB );
use Graph::Traversal::DFS;
use List::Util qw( all any first min none sum0 uniq );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    write_SMILES
);

my %shape_to_SP = ( 'U' => '@SP1', '4' => '@SP2', 'Z' => '@SP3' );
my %SP_to_shape = reverse %shape_to_SP;

sub write_SMILES
{
    my( $what, $options ) = @_;
    # Backwards compatibility with the old API where second parameter was
    # a subroutine reference for ordering:
    my $order_sub = defined $options && ref $options eq 'CODE' ? $options : \&_order;
    $options = {} unless defined $options && ref $options eq 'HASH';

    $order_sub = $options->{order_sub} if $options->{order_sub};
    my $raw = $options->{raw};

    # Subroutine will also accept and properly represent a single atom:
    return _pre_vertex( $what, undef, { raw => $raw } ) if ref $what eq 'HASH';

    my @moieties = ref $what eq 'ARRAY' ? @$what : ( $what );
    my @components;

    for my $graph (@moieties) {
        my @symbols;
        my %vertex_symbols;
        my $nrings = 0;
        my %seen_rings;
        my @chiral;
        my %discovered_from;

        my $rings = {};

        my $operations = {
            tree_edge     => sub { my( $seen, $unseen, $self ) = @_;
                                   if( $vertex_symbols{$unseen} ) {
                                       ( $seen, $unseen ) = ( $unseen, $seen );
                                   }
                                   push @symbols, _tree_edge( $seen, $unseen, $self, $order_sub );
                                   $discovered_from{$unseen} = $seen },

            non_tree_edge => sub { my @sorted = sort { $vertex_symbols{$a} <=>
                                                       $vertex_symbols{$b} }
                                                     @_[0..1];
                                   $rings->{$vertex_symbols{$_[0]}}
                                           {$vertex_symbols{$_[1]}} =
                                   $rings->{$vertex_symbols{$_[1]}}
                                           {$vertex_symbols{$_[0]}} =
                                        _depict_bond( @sorted, $graph ) },

            pre  => sub { my( $vertex, $dfs ) = @_;
                          push @chiral, $vertex if is_chiral $vertex;
                          push @symbols,
                          _pre_vertex( $vertex,
                                       $graph,
                                       { omit_chirality => 1,
                                         raw => $raw } );
                          $vertex_symbols{$vertex} = $#symbols },

            post => sub { push @symbols, ')' },
            next_root => undef,
        };

        if( $order_sub ) {
            $operations->{first_root} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
            $operations->{next_successor} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
        }

        my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
        $traversal->dfs;

        if( scalar keys %vertex_symbols != scalar $graph->vertices ) {
            warn scalar( $graph->vertices ) - scalar( keys %vertex_symbols ) .
                 ' unreachable atom(s) detected in moiety' . "\n";
        }

        next unless @symbols;
        pop @symbols;

        # Dealing with chirality
        for my $atom (@chiral) {
            next unless $atom->{chirality} =~ /^@(@?|SP[123]|TB1?[1-9]|TB20)$/;

            my @neighbours = $graph->neighbours($atom);
            my $has_lone_pair;
            if( $atom->{chirality} =~ /^@(@?|SP[123])$/ ) {
                if( scalar @neighbours < 3 || scalar @neighbours > 4 ) {
                    warn "chirality '$atom->{chirality}' observed for atom " .
                         'with ' . scalar @neighbours . ' neighbours, can only ' .
                         'process tetrahedral chiral or square planar centers ' .
                         'with possible lone pairs' . "\n";
                    next;
                }
                $has_lone_pair = @neighbours == 3;
            }
            if( $atom->{chirality} =~ /^\@TB..?$/ ) {
                if( scalar @neighbours < 4 || scalar @neighbours > 5 ) {
                    warn "chirality '$atom->{chirality}' observed for atom " .
                         'with ' . scalar @neighbours . ' neighbours, can only ' .
                         'process trigonal bipyramidal centers ' .
                         'with possible lone pairs' . "\n";
                    next;
                }
                $has_lone_pair = @neighbours == 4;
            }
            if( $atom->{chirality} =~ /^\@OH..?$/ ) {
                if( scalar @neighbours < 5 || scalar @neighbours > 6 ) {
                    warn "chirality '$atom->{chirality}' observed for atom " .
                         'with ' . scalar @neighbours . ' neighbours, can only ' .
                         'process octahedral centers ' .
                         'with possible lone pairs' . "\n";
                    next;
                }
                $has_lone_pair = @neighbours == 5;
            }

            my $chirality_now = $atom->{chirality};
            if( $atom->{chirality_neighbours} ) {
                if( scalar @neighbours !=
                    scalar @{$atom->{chirality_neighbours}} ) {
                    warn 'number of neighbours does not match the length ' .
                         "of 'chirality_neighbours' array, cannot process " .
                         'such chiral centers' . "\n";
                    next;
                }

                my %indices;
                for (0..$#{$atom->{chirality_neighbours}}) {
                    my $pos = $_;
                    if( $has_lone_pair && $_ != 0 ) {
                        # Lone pair is always second in the chiral neighbours array
                        $pos++;
                    }
                    $indices{$vertex_symbols{$atom->{chirality_neighbours}[$_]}} = $pos;
                }

                my @order_new;
                # In the newly established order, the atom from which this one
                # is discovered (left hand side) will be the first, if any
                if( $discovered_from{$atom} ) {
                    push @order_new,
                         $indices{$vertex_symbols{$discovered_from{$atom}}};
                }
                # Second, there will be ring bonds as they are added before all of the neighbours
                if( $rings->{$vertex_symbols{$atom}} ) {
                    push @order_new, map  { $indices{$_} }
                                     sort { $a <=> $b }
                                     keys %{$rings->{$vertex_symbols{$atom}}};
                }
                # Finally, all neighbours are added, uniq will remove duplicates
                push @order_new, map  { $indices{$_} }
                                 sort { $a <=> $b }
                                 map  { $vertex_symbols{$_} }
                                      @neighbours;
                @order_new = uniq @order_new;

                if( $has_lone_pair ) {
                    # Accommodate the lone pair
                    if( $discovered_from{$atom} ) {
                        @order_new = ( $order_new[0], 1, @order_new[1..$#order_new] );
                    } else {
                        unshift @order_new, 1;
                    }
                }

                if( $atom->{chirality} =~ /^@@?$/ ) {
                    # Tetragonal centers
                    if( join( '', _permutation_order( @order_new ) ) ne '0123' ) {
                        $chirality_now = $chirality_now eq '@' ? '@@' : '@';
                    }
                } elsif( $atom->{chirality} =~ /^\@SP[123]$/ ) {
                    # Square planar centers
                    $chirality_now = _square_planar_chirality( @order_new, $chirality_now );
                } elsif( $atom->{chirality} =~ /^\@TB..?$/ ) {
                    # Trigonal bipyramidal centers
                    $chirality_now = _trigonal_bipyramidal_chirality( @order_new, $chirality_now );
                } else {
                    # Octahedral centers
                }
            }

            my $parser = Chemistry::OpenSMILES::Parser->new;
            my( $graph_reparsed ) = $parser->parse( $symbols[$vertex_symbols{$atom}],
                                                    { raw => 1 } );
            my( $atom_reparsed ) = $graph_reparsed->vertices;
            $atom_reparsed->{chirality} = $chirality_now;
            $symbols[$vertex_symbols{$atom}] =
                write_SMILES( $atom_reparsed );
        }

        # Adding ring numbers
        my @ring_ids = ( 1..99, 0 );
        my @ring_ends;
        for my $i (0..$#symbols) {
            if( $rings->{$i} ) {
                for my $j (sort { $a <=> $b } keys %{$rings->{$i}}) {
                    next if $i > $j;
                    if( !@ring_ids ) {
                        # All 100 rings are open now. There is no other
                        # solution but to terminate the program.
                        die 'cannot represent more than 100 open ring' .
                            ' bonds';
                    }
                    $symbols[$i] .= $rings->{$i}{$j} .
                                    ($ring_ids[0] < 10 ? '' : '%') .
                                     $ring_ids[0];
                    $symbols[$j] .= ($rings->{$i}{$j} eq '/'  ? '\\' :
                                     $rings->{$i}{$j} eq '\\' ? '/'  :
                                     $rings->{$i}{$j}) .
                                    ($ring_ids[0] < 10 ? '' : '%') .
                                     $ring_ids[0];
                    push @{$ring_ends[$j]}, shift @ring_ids;
                }
            }
            if( $ring_ends[$i] ) {
                # Ring bond '0' must stay in the end
                @ring_ids = sort { ($a == 0) - ($b == 0) || $a <=> $b }
                                 (@{$ring_ends[$i]}, @ring_ids);
            }
        }

        push @components, join '', @symbols;
    }

    return join '.', @components;
}

# DEPRECATED
sub write
{
    &write_SMILES;
}

sub _tree_edge
{
    my( $u, $v, $self ) = @_;

    return '(' . _depict_bond( $u, $v, $self->graph );
}

sub _pre_vertex
{
    my( $vertex, $graph, $options ) = @_;
    $options = {} unless $options;
    my( $omit_chirality,
        $raw ) =
      ( $options->{omit_chirality},
        $options->{raw} );

    my $atom = $vertex->{symbol};
    my $is_simple = $atom =~ /^[bcnosp]$/i ||
                    $atom =~ /^(F|Cl|Br|I|\*)$/;

    if( exists $vertex->{isotope} ) {
        $atom = $vertex->{isotope} . $atom;
        $is_simple = 0;
    }

    if( is_chiral $vertex && !$omit_chirality ) {
        $atom .= $vertex->{chirality};
        $is_simple = 0;
    }

    if( $vertex->{hcount} ) { # if non-zero
        $atom .= 'H' . ($vertex->{hcount} == 1 ? '' : $vertex->{hcount});
        $is_simple = 0;
    }
    $is_simple = 0 if $raw && exists $vertex->{hcount};

    if( $vertex->{charge} ) { # if non-zero
        $atom .= ($vertex->{charge} > 0 ? '+' : '') . $vertex->{charge};
        $atom =~ s/([-+])1$/$1/;
        $is_simple = 0;
    }

    if( $vertex->{class} ) { # if non-zero
        $atom .= ':' . $vertex->{class};
        $is_simple = 0;
    }

    # Decide whether to put atom in square brackets because of unusual valence
    if( $is_simple && $graph && !$raw && $normal_valence{ucfirst $atom} ) {
        my $valence = valence( $graph, $vertex );
        $is_simple = any { $_ == $valence }
                         @{$normal_valence{ucfirst $atom}};
    }

    return $is_simple ? $atom : "[$atom]";
}

sub _depict_bond
{
    my( $u, $v, $graph ) = @_;

    if( !$graph->has_edge_attribute( $u, $v, 'bond' ) ) {
        return is_aromatic $u && is_aromatic $v ? '-' : '';
    }

    my $bond = $graph->get_edge_attribute( $u, $v, 'bond' );
    return $bond if $bond ne '/' && $bond ne '\\';
    return $bond if $u->{number} < $v->{number};
    return toggle_cistrans $bond;
}

# Reorder a permutation of elements 0, 1, 2 and 3 by taking an element
# and moving it two places either forward or backward in the line. This
# subroutine is used to check whether a sign change of tetragonal
# chirality is required or not.
sub _permutation_order
{
    # Safeguard against endless cycles due to undefined values
    if( (scalar @_ != 4) ||
        (any { !defined || !/^[0-3]$/ } @_) ||
        (join( ',', sort @_ ) ne '0,1,2,3') ) {
        warn '_permutation_order() accepts only permutations of numbers ' .
             "'0', '1', '2' and '3', unexpected input received";
        return 0..3; # Return original order
    }

    while( $_[2] == 0 || $_[3] == 0 ) {
        @_ = ( $_[0], @_[2..3], $_[1] );
    }
    if( $_[0] != 0 ) {
        @_ = ( @_[1..2], $_[0], $_[3] );
    }
    while( $_[1] != 1 ) {
        @_[1..3] = ( @_[2..3], $_[1] );
    }
    return @_;
}

sub _square_planar_chirality
{
    my $chirality = pop @_;
    my @source = 0..3;
    my @target = @_;

    if( join( ',', sort @_ ) ne '0,1,2,3' ) {
        die '_square_planar_chirality() accepts only permutations of ' .
            "numbers '0', '1', '2' and '3', unexpected input received";
    }

    # Rotations until 0 is first
    while( $source[0] != $target[0] ) {
        push @source, shift @source;
        my %tab = ( '@SP1' => '@SP1', '@SP2' => '@SP3', '@SP3' => '@SP2' );
        $chirality = $tab{$chirality};
    }

    if( $source[3] == $target[1] ) { # Swap the right side
        ( $source[2], $source[3] ) = ( $source[3], $source[2] );
        my %tab = ( '@SP1' => '@SP3', '@SP2' => '@SP2', '@SP3' => '@SP1' );
        $chirality = $tab{$chirality};
    }

    if( $source[2] == $target[1] ) { # Swap the center
        ( $source[1], $source[2] ) = ( $source[2], $source[1] );
        my %tab = ( '@SP1' => '@SP2', '@SP2' => '@SP1', '@SP3' => '@SP3' );
        $chirality = $tab{$chirality};
    }

    if( $source[3] == $target[2] ) { # Swap the right side
        ( $source[2], $source[3] ) = ( $source[3], $source[2] );
        my %tab = ( '@SP1' => '@SP3', '@SP2' => '@SP2', '@SP3' => '@SP1' );
        $chirality = $tab{$chirality};
    }

    return $chirality;
}

sub _trigonal_bipyramidal_chirality
{
    my $chirality = pop @_;
    my @order = @_;

    $chirality = int substr $chirality, 3;
    my $TB = $TB[$chirality - 1];
    my @axis = map { $_ - 1 } @{$TB->{axis}};
    my $order = $TB->{order};
    my $opposite = 1 + first { $TB[$_]->{axis}[0] == $TB->{axis}[0] &&
                               $TB[$_]->{axis}[1] == $TB->{axis}[1] &&
                               $TB[$_]->{order}   ne $TB->{order} } 0..$#TB;

    if( ($order[$axis[0]] == $axis[0] && $order[$axis[1]] == $axis[1]) ||
        ($order[$axis[0]] == $axis[1] && $order[$axis[1]] == $axis[0]) ) {
        # Axis is the same or inverted
        @order = grep { $_ != $axis[0] && $_ != $axis[1] } @order;
        while( $order[0] != min @order ) {
            push @order, shift @order;
        }
        if( $order[$axis[0]] == $axis[1] && $order[$axis[1]] == $axis[0] ) {
            ( $chirality, $opposite ) = ( $opposite, $chirality );
        }
        return '@TB' . $chirality if $order[1] < $order[2];
        return '@TB' . $opposite;
    } else {
        # Axis has changed
        my @axis_now = ( (first { $order[$_] == $axis[0] } 0..4),
                         (first { $order[$_] == $axis[1] } 0..4) );
        $chirality = 1 +  first { $TB[$_]->{axis}[0] == $axis_now[0] + 1 &&
                                  $TB[$_]->{axis}[1] == $axis_now[1] + 1 &&
                                  $TB[$_]->{order}   eq $order } 0..$#TB;
        $opposite  = 1 +  first { $TB[$_]->{axis}[0] == $axis_now[0] + 1 &&
                                  $TB[$_]->{axis}[1] == $axis_now[1] + 1 &&
                                  $TB[$_]->{order}   ne $order } 0..$#TB;
        @order = grep { $_ != $axis_now[0] && $_ != $axis_now[1] } @order;
        while( $order[0] != min @order ) {
            push @order, shift @order;
        }
        return '@TB' . $chirality if $order[1] < $order[2];
        return '@TB' . $opposite;
    }
}

sub _octahedral_chirality
{
    my $chirality = pop @_;
    my @order = @_;

    $chirality = int substr $chirality, 3;
    my $OH = $OH[$chirality - 1];
    my $shape = $OH->{shape};
    my @axis = map { $_ - 1 } @{$OH->{axis}};
    my $order = $OH->{order};

    if( ($order[$axis[0]] == $axis[0] && $order[$axis[1]] == $axis[1]) ||
        ($order[$axis[0]] == $axis[1] && $order[$axis[1]] == $axis[0]) ) {
        # Axis is the same or inverted
        my $SP = _square_planar_chirality( (map { $_ - 1 } @order), $shape_to_SP{$shape} );
        # If axis is inverted, direction has to be inverted as well
        # CHECKME: Does the change of shape affect direction?
        if( $order[$axis[0]] == $axis[1] && $order[$axis[1]] == $axis[0] ) {
            $order = $order eq '@' ? '@@' : '@';
        }
        $chirality = 1 + first { $OH[$_]->{shape} eq $SP_to_shape{$SP} &&
                                 $OH[$_]->{axis}[0] == 1 && $OH[$_]->{axis}[1] == 6 &&
                                 $OH[$_]->{order} eq $order } 0..$#OH;
        return '@OH' . $chirality;
    } else {
        # Axis has changed
        my @axes = ( \@axis );
        my @remaining_numbers = grep { $_ != $axis[0] && $_ != $axis[1] } 0..5;
        @remaining_numbers = map { $remaining_numbers[$_] } ( 0, 3, 1, 2 ) if $shape eq '4';
        @remaining_numbers = map { $remaining_numbers[$_] } ( 0, 1, 3, 2 ) if $shape eq 'Z';
        @remaining_numbers = reverse @remaining_numbers if $order eq '@@';
        # TODO: Change of axis direction inverts the sign.
        # TODO: When axis A is replaced by axis B, axis C remains unchanged.
        # TODO: If axis change is to @, A is left untouched, replaces B.
        # TODO: If axis change is to @@, A is inverted, replaces B.
    }
}

sub _order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$a}{number} <=>
                        $vertices->{$b}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}

1;
