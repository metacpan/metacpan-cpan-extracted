package Chemistry::OpenSMILES::Stereo;

# ABSTRACT: Stereochemistry handling routines
our $VERSION = '0.11.0'; # VERSION

use strict;
use warnings;

use Chemistry::OpenSMILES qw(
    is_chiral
    is_cis_trans_bond
    is_double_bond
    is_ring_bond
    is_single_bond
    toggle_cistrans
);
use Chemistry::OpenSMILES::Stereo::Tables qw( @TB );
use Chemistry::OpenSMILES::Writer qw( write_SMILES );
use Graph::Traversal::BFS;
use Graph::Undirected;
use List::Util qw( all any first max min sum sum0 uniq );
use Set::Object qw( set );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    chirality_to_pseudograph
    cis_trans_to_pseudoedges
    mark_all_double_bonds
    mark_cis_trans
);

sub mark_all_double_bonds
{
    my( $graph, $setting_sub, $order_sub, $color_sub ) = @_;

    my @double_bonds = grep { is_double_bond( $graph, @$_ ) } $graph->edges;
    if( ref $setting_sub eq 'ARRAY' ) {
        # List of double bonds with their setting are given
        @double_bonds = map { [ @{$_}[1..2] ] } @$setting_sub;
        my %cis = map { ( join( '', sort @{$_}[1..2] ) => { atoms => set( $_->[0], $_->[3] ), setting => $_->[4] } ) }
                      @$setting_sub;
        $setting_sub = sub {
            my $key = join '', sort @_[1..2];
            return undef unless exists $cis{$key};

            my $setting = $cis{$key}->{setting};
            return $setting unless ($cis{$key}->{atoms} * set( $_[0], $_[3] ))->size == 1;
            return $setting eq 'cis' ? 'trans' : 'cis';
        };
    }

    # By default, whenever there is a choice between atoms, the one with
    # lowest position in the input SMILES is chosen:
    $order_sub = sub { $_[0]->{number} } unless $order_sub;

    # Select non-ring double bonds
    @double_bonds = grep { !is_ring_bond( $graph, @$_ ) &&
                           !is_unimportant_double_bond( $graph, @$_, $color_sub ) }
                         @double_bonds;

    return unless @double_bonds;

    # Construct a double bond incidence graph. Vertices are double bonds
    # and edges are between those double bonds that separated by a single
    # single ('-') bond. Interestingly, incidence graph for SMILES C=C(C)=C
    # is connected, but for C=C=C not. This is because allenal systems
    # cannot be represented yet. 
    my $bond_graph = Graph::Undirected->new;
    my %incident_double_bonds;
    for my $bond (@double_bonds) {
        $bond_graph->add_vertex( join '', sort @$bond );
        push @{$incident_double_bonds{$bond->[0]}}, $bond;
        push @{$incident_double_bonds{$bond->[1]}}, $bond;
    }
    for my $bond ($graph->edges) {
        next unless is_single_bond( $graph, @$bond );
        my @adjacent_bonds;
        if( $incident_double_bonds{$bond->[0]} ) {
            push @adjacent_bonds,
                 @{$incident_double_bonds{$bond->[0]}};
        }
        if( $incident_double_bonds{$bond->[1]} ) {
            push @adjacent_bonds,
                 @{$incident_double_bonds{$bond->[1]}};
        }
        for my $bond1 (@adjacent_bonds) {
            for my $bond2 (@adjacent_bonds) {
                next if $bond1 == $bond2;
                $bond_graph->add_edge( join( '', sort @$bond1 ),
                                       join( '', sort @$bond2 ) );
            }
        }
    }

    # In principle, bond graph could be splitted into separate components
    # to reduce the number of cycles needed by Morgan algorithm, but I do
    # not think there is a failure case because of keeping them together.

    # Set up initial invariants
    my %invariants;
    for ($bond_graph->vertices) {
        $invariants{$_} = $bond_graph->degree( $_ );
    }
    my %distinct_invariants = map { $_ => 1 } values %invariants;

    # Perform Morgan algorithm
    while( 1 ) {
        my %invariants_now;
        for ($bond_graph->vertices) {
            $invariants_now{$_} = sum0 map { $invariants{$_} }
                                           $bond_graph->neighbours( $_ );
        }

        my %distinct_invariants_now = map { $_ => 1 } values %invariants_now;
        last if %distinct_invariants_now <= %distinct_invariants;

        %invariants = %invariants_now;
        %distinct_invariants = %distinct_invariants_now;
    }

    # Establish a deterministic order favouring bonds with higher invariants.
    # If invariants are equal, order bonds by their atom numbers.
    @double_bonds = sort { $invariants{join '', sort @$b} <=>
                           $invariants{join '', sort @$a} ||
                           (min map { $order_sub->($_) } @$a) <=>
                           (min map { $order_sub->($_) } @$b) ||
                           (max map { $order_sub->($_) } @$a) <=>
                           (max map { $order_sub->($_) } @$b) } @double_bonds;

    for (@double_bonds) {
        mark_cis_trans( $graph, @$_, $setting_sub, $order_sub );
    }
}

# Requires double bonds in input. Does not check whether a bond belongs
# to a ring or not.
sub mark_cis_trans
{
    my( $graph, $atom2, $atom3, $setting_sub, $order_sub ) = @_;

    # By default, whenever there is a choice between atoms, the one with
    # lowest position in the input SMILES is chosen:
    $order_sub = sub { $_[0]->{number} } unless $order_sub;

    my @neighbours2 = $graph->neighbours( $atom2 );
    my @neighbours3 = $graph->neighbours( $atom3 );
    return if @neighbours2 < 2 || @neighbours3 < 2;

    # TODO: Currently we are choosing either a pair of
    # neighbouring atoms which have no cis/trans markers or
    # a pair of which a single atom has a cis/trans marker.
    # The latter case allows to accommodate adjacent double
    # bonds. However, there may be a situation where both
    # atoms already have cis/trans markers, but could still
    # be reconciled.

    my @cistrans_bonds2 =
        grep { is_cis_trans_bond( $graph, $atom2, $_ ) } @neighbours2;
    my @cistrans_bonds3 =
        grep { is_cis_trans_bond( $graph, $atom3, $_ ) } @neighbours3;

    if( @cistrans_bonds2 + @cistrans_bonds3 > 1 ) {
        warn 'cannot represent cis/trans bond between atoms ' .
             join( ' and ', sort map { $_->{number} } $atom2, $atom3 ) .
             ' as there are other cis/trans bonds nearby' . "\n";
        return;
    }

    if( (@neighbours2 == 2 && !@cistrans_bonds2 &&
         !any { is_single_bond( $graph, $atom2, $_ ) } @neighbours2) ||
        (@neighbours3 == 2 && !@cistrans_bonds3 &&
         !any { is_single_bond( $graph, $atom3, $_ ) } @neighbours3) ) {
        # Azide group (N=N#N) or conjugated allene-like systems (=C=)
        warn 'atoms ' .
             join( ' and ', sort map { $_->{number} } $atom2, $atom3 ) .
             ' are part of conjugated double/triple bond system, thus ' .
             'cis/trans setting of their bond is impossible to represent ' .
             '(not supported yet)' . "\n";
        return;
    }

    # Making the $atom2 be the one which has a defined cis/trans bond.
    # Also, a deterministic ordering of atoms in bond is achieved here.
    if(   @cistrans_bonds3 ||
        (!@cistrans_bonds2 && $order_sub->($atom2) > $order_sub->($atom3)) ) {
        ( $atom2, $atom3 ) = ( $atom3, $atom2 );
        @neighbours2 = $graph->neighbours( $atom2 );
        @neighbours3 = $graph->neighbours( $atom3 );

        @cistrans_bonds2 = @cistrans_bonds3;
        @cistrans_bonds3 = ();
    }

    # Establishing the canonical order
    @neighbours2 = sort { $order_sub->($a) <=> $order_sub->($b) }
                   grep { is_single_bond( $graph, $atom2, $_ ) } @neighbours2;
    @neighbours3 = sort { $order_sub->($a) <=> $order_sub->($b) }
                   grep { is_single_bond( $graph, $atom3, $_ ) } @neighbours3;

    # Check if there is a chance to have anything marked
    my $bond_will_be_marked;
    for my $atom1 (@cistrans_bonds2, @neighbours2) {
        for my $atom4 (@neighbours3) {
            my $setting = $setting_sub->( $atom1, $atom2, $atom3, $atom4 );
            if( $setting ) {
                $bond_will_be_marked = 1;
                last;
            }
        }
    }

    if( !$bond_will_be_marked ) {
        warn 'cannot represent cis/trans bond between atoms ' .
             join( ' and ', sort map { $_->{number} } $atom2, $atom3 ) .
             ' as there are no eligible single bonds nearby' . "\n";
        return;
    }

    # If there is an atom with cis/trans bond, then this is this one
    my( $first_atom ) = @cistrans_bonds2 ? @cistrans_bonds2 : @neighbours2;
    if( !@cistrans_bonds2 ) {
        $graph->set_edge_attribute( $first_atom, $atom2, 'bond', '/' );
    }

    my $atom4_marked;
    for my $atom4 (@neighbours3) {
        my $atom1 = $first_atom;
        my $setting = $setting_sub->( $atom1, $atom2, $atom3, $atom4 );
        next unless $setting;
        my $other = $graph->get_edge_attribute( $atom1, $atom2, 'bond' );
        $other = toggle_cistrans $other if $setting eq 'cis';
        $other = toggle_cistrans $other if $atom1->{number} > $atom2->{number};
        $other = toggle_cistrans $other if $atom4->{number} < $atom3->{number};
        $graph->set_edge_attribute( $atom3, $atom4, 'bond', $other );
        $atom4_marked = $atom4 unless $atom4_marked;
    }

    for my $atom1 (@neighbours2) {
        next if $atom1 eq $first_atom; # Marked already
        my $atom4 = $atom4_marked;
        my $setting = $setting_sub->( $atom1, $atom2, $atom3, $atom4 );
        next unless $setting;
        my $other = $graph->get_edge_attribute( $atom3, $atom4, 'bond' );
        $other = toggle_cistrans $other if $setting eq 'cis';
        $other = toggle_cistrans $other if $atom1->{number} > $atom2->{number};
        $other = toggle_cistrans $other if $atom4->{number} < $atom3->{number};
        $graph->set_edge_attribute( $atom1, $atom2, 'bond', $other );
    }
}

# Store chirality character as additional pseudo vertices and edges.
sub chirality_to_pseudograph
{
    my( $moiety ) = @_;

    for my $atom ($moiety->vertices) {
        next unless is_chiral $atom;

        my $has_lone_pair;
        my @chirality_neighbours = @{$atom->{chirality_neighbours}};

        if( Chemistry::OpenSMILES::is_chiral_tetrahedral( $atom ) ||
            Chemistry::OpenSMILES::is_chiral_planar( $atom ) ) {
            next unless @chirality_neighbours >= 3 &&
                        @chirality_neighbours <= 4;
            $has_lone_pair = @chirality_neighbours == 3;
        } elsif( Chemistry::OpenSMILES::is_chiral_trigonal_bipyramidal( $atom ) ) {
            next unless @chirality_neighbours >= 4 &&
                        @chirality_neighbours <= 5;
            $has_lone_pair = @chirality_neighbours == 4;
        }

        if( $has_lone_pair ) {
            @chirality_neighbours = ( $chirality_neighbours[0],
                                      {}, # marking the lone pair
                                      @chirality_neighbours[1..$#chirality_neighbours] );
        }

        if( Chemistry::OpenSMILES::is_chiral_tetrahedral( $atom ) ) {
            # Algorithm is described in detail in doi:10.1186/s13321-023-00692-1
            if( $atom->{chirality} eq '@' ) {
                # Reverse the order if counter-clockwise
                @chirality_neighbours = ( $chirality_neighbours[0],
                                          reverse @chirality_neighbours[1..3] );
            }

            for my $i (0..3) {
                my $neighbour = $chirality_neighbours[$i];
                my @chirality_neighbours_now = @chirality_neighbours;

                if( $i % 2 ) {
                    # Reverse the order due to projected atom change
                    @chirality_neighbours_now = ( $chirality_neighbours_now[0],
                                                  reverse @chirality_neighbours_now[1..3] );
                }

                my @other = grep { $_ != $neighbour } @chirality_neighbours_now;
                for my $offset (0..2) {
                    my $connector = {};
                    $moiety->set_edge_attribute( $neighbour, $connector, 'chiral', 'from' );
                    $moiety->set_edge_attribute( $atom, $connector, 'chiral', 'to' );

                    $moiety->set_edge_attribute( $connector, $other[0], 'chiral', 1 );
                    $moiety->set_edge_attribute( $connector, $other[1], 'chiral', 2 );
                    $moiety->set_edge_attribute( $connector, $other[2], 'chiral', 3 );

                    push @other, shift @other;
                }
            }
        } elsif( Chemistry::OpenSMILES::is_chiral_planar( $atom ) ) {
            # For square planar environments it is enough to retain the enumeration order of atoms.
            # To do so, "neighbouring neighbours" are connected together and a link to central atom is placed.
            if(      $atom->{chirality} eq '@SP2' ) { # 4
                @chirality_neighbours = map { $chirality_neighbours[$_] } ( 0, 2, 1, 3 );
            } elsif( $atom->{chirality} eq '@SP3' ) { # Z
                @chirality_neighbours = map { $chirality_neighbours[$_] } ( 0, 1, 3, 2 );
            }

            for my $i (0..3) {
                my $connector = {};
                $moiety->set_edge_attribute( $atom, $connector, 'chiral', 'center' );
                $moiety->set_edge_attribute( $connector, $chirality_neighbours[$i], 'chiral', 'neighbour' );
                $moiety->set_edge_attribute( $connector, $chirality_neighbours[($i + 1) % 4], 'chiral', 'neighbour' );
            }
        } else { # Trigonal bipyrimidal
            my $number = substr $atom->{chirality}, 3;
            my $setting = $TB[$number - 1];

            my @axis  = map  { $chirality_neighbours[$_ - 1] } @{$setting->{axis}};
            my @other = grep { $_ != $axis[0] && $_ != $axis[1] }
                        map  { $chirality_neighbours[$_] } 0..4;
            @other = reverse @other if $setting->{order} eq '@@';

            for my $from (@axis) {
                my $to = first { $_ != $from } @axis;
                for my $offset (0..2) {
                    my $connector = {};
                    $moiety->set_edge_attribute( $from, $connector, 'chiral', 'from' );
                    $moiety->set_edge_attribute( $atom, $connector, 'chiral', 'center' );
                    $moiety->set_edge_attribute( $to,   $connector, 'chiral', 'to' );

                    $moiety->set_edge_attribute( $connector, $other[-1], 'chiral', 'counter-clockwise' );
                    $moiety->set_edge_attribute( $connector, $other[ 1], 'chiral', 'clockwise' );

                    push @other, shift @other;
                }
                @other = reverse @other; # Inverting the axis
            }
        }
    }
}

sub cis_trans_to_pseudoedges
{
    my( $moiety ) = @_;

    # Select non-ring double bonds
    my @double_bonds =
        grep {  is_double_bond( $moiety, @$_ ) &&
               !is_ring_bond( $moiety, @$_ ) &&
               !is_unimportant_double_bond( $moiety, @$_ ) } $moiety->edges;

    # Connect cis/trans atoms in double bonds with pseudo-edges
    for my $bond (@double_bonds) {
        my( $atom2, $atom3 ) = @$bond;
        my @atom2_neighbours = grep { !is_pseudoedge( $moiety, $atom2, $_ ) }
                                    $moiety->neighbours( $atom2 );
        my @atom3_neighbours = grep { !is_pseudoedge( $moiety, $atom3, $_ ) }
                                    $moiety->neighbours( $atom3 );
        next if @atom2_neighbours < 2 || @atom2_neighbours > 3 ||
                @atom3_neighbours < 2 || @atom3_neighbours > 3;

        my $atom1 = first { is_cis_trans_bond( $moiety, $atom2, $_ ) }
                          @atom2_neighbours;
        my $atom4 = first { is_cis_trans_bond( $moiety, $atom3, $_ ) }
                          @atom3_neighbours;
        next unless $atom1 && $atom4;

        my $atom1_para = first { $_ != $atom1 && $_ != $atom3 } @atom2_neighbours;
        my $atom4_para = first { $_ != $atom4 && $_ != $atom2 } @atom3_neighbours;

        my $is_cis = $moiety->get_edge_attribute( $atom1, $atom2, 'bond' ) ne
                     $moiety->get_edge_attribute( $atom3, $atom4, 'bond' );

        $is_cis = !$is_cis if $atom1->{number} > $atom2->{number};
        $is_cis = !$is_cis if $atom3->{number} > $atom4->{number};

        $moiety->set_edge_attribute( $atom1, $atom4, 'pseudo',
                                     $is_cis ? 'cis' : 'trans' );
        if( $atom1_para ) {
            $moiety->set_edge_attribute( $atom1_para, $atom4, 'pseudo',
                                         $is_cis ? 'trans' : 'cis' );
        }
        if( $atom4_para ) {
            $moiety->set_edge_attribute( $atom1, $atom4_para, 'pseudo',
                                         $is_cis ? 'trans' : 'cis' );
        }
        if( $atom1_para && $atom4_para ) {
            $moiety->set_edge_attribute( $atom1_para, $atom4_para, 'pseudo',
                                         $is_cis ? 'cis' : 'trans' );
        }
    }

    # Unset cis/trans bond markers during second pass
    for my $bond ($moiety->edges) {
        next unless is_cis_trans_bond( $moiety, @$bond );
        $moiety->delete_edge_attribute( @$bond, 'bond' );
    }
}

sub is_pseudoedge
{
    my( $moiety, $a, $b ) = @_;
    return $moiety->has_edge_attribute( $a, $b, 'pseudo' );
}

# An "unimportant" double bond is one which has chemically identical atoms on one of its sides.
# If C<$color_sub> is given, it is used to determine chemical identity of atoms.
# If not, only leaf atoms are considered and compared.
sub is_unimportant_double_bond
{
    my( $moiety, $a, $b, $color_sub ) = @_;
    my @a_neighbours = grep { $_ != $b } $moiety->neighbours( $a );
    my @b_neighbours = grep { $_ != $a } $moiety->neighbours( $b );

    for (\@a_neighbours, \@b_neighbours) {
        next unless @$_ == 2;

        my @representations;
        if( $color_sub ) {
            @representations = map { $color_sub->( $_ ) } @$_;
        } else {
            next if any { $moiety->degree( $_ ) != 1 } @$_;
            @representations = map { write_SMILES( $_ ) } @$_;
        }
        return 1 if uniq( @representations ) == 1;
    }

    return;
}

1;
