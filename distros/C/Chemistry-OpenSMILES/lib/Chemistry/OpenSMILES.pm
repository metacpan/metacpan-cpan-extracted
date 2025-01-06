package Chemistry::OpenSMILES;

# ABSTRACT: OpenSMILES format reader and writer
our $VERSION = '0.11.0'; # VERSION

use strict;
use warnings;
use 5.0100;

use Chemistry::OpenSMILES::Stereo::Tables qw( @OH @TB );
use Graph::Traversal::BFS;
use List::Util qw( all any first none sum0 );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    %bond_order_to_symbol
    %bond_symbol_to_order
    %normal_valence
    clean_chiral_centers
    is_aromatic
    is_chiral
    is_chiral_allenal
    is_chiral_octahedral
    is_chiral_planar
    is_chiral_tetrahedral
    is_chiral_trigonal_bipyramidal
    is_cis_trans_bond
    is_double_bond
    is_ring_atom
    is_ring_bond
    is_single_bond
    is_triple_bond
    mirror
    toggle_cistrans
    valence
);

sub is_chiral($);
sub is_chiral_planar($);
sub is_chiral_tetrahedral($);
sub mirror($);
sub toggle_cistrans($);

our %normal_valence = (
    B  => [ 3 ],
    C  => [ 4 ],
    N  => [ 3, 5 ],
    O  => [ 2 ],
    P  => [ 3, 5 ],
    S  => [ 2, 4, 6 ],
    F  => [ 1 ],
    Cl => [ 1 ],
    Br => [ 1 ],
    I  => [ 1 ],
    c  => [ 3 ], # Not from OpenSMILES specification
);

our %bond_order_to_symbol = (
    1   => '-',
    1.5 => ':',
    2   => '=',
    3   => '#',
    4   => '$',
);

our %bond_symbol_to_order = (
    '-' => 1,
    ':' => 1.5,
    '=' => 2,
    '#' => 3,
    '$' => 4,
);

# Removes chiral setting from allenal, square planar, tetrahedral and trigonal bipyramidal chiral centers if deemed unimportant.
# For allenal, tetrahedral and trigonal bipyramidal arrangements when not all the neighbours are distinct.
# For square planar arrangements this means situations when all neighbours are the same.
# Chiral centers with lone pairs are left untouched.
# Returns the affected atoms.
#
# TODO: check other chiral centers
sub clean_chiral_centers($$)
{
    my( $moiety, $color_sub ) = @_;

    my @affected;
    for my $atom ($moiety->vertices) {
        next unless is_chiral_allenal( $atom ) ||
                    is_chiral_planar( $atom )  ||
                    is_chiral_tetrahedral( $atom ) ||
                    is_chiral_trigonal_bipyramidal( $atom );
        # Anomers must not loose chirality settings in any way
        next if is_ring_atom( $moiety, $atom, scalar $moiety->edges );

        my $hcount = exists $atom->{hcount} ? $atom->{hcount} : 0;
        my @neighbours = $moiety->neighbours( $atom );
        if( is_chiral_allenal( $atom ) ) {
            @neighbours = grep { $_ != $atom }
                          map  { $moiety->neighbours( $_ ) }
                               @neighbours;
        }

        if( is_chiral_trigonal_bipyramidal( $atom ) ) {
            next if @neighbours + $hcount != 5;
        } else {
            next if @neighbours + $hcount != 4;
        }

        my %colors;
        for (@neighbours, ( { symbol => 'H' } ) x $hcount) {
            $colors{$color_sub->( $_ )}++;
        }

        if( is_chiral_planar( $atom ) ) {
            # Chiral planar center markers make sense even if only two types of atoms are there.
            next if scalar keys %colors  > 2;
            next if scalar keys %colors == 2 && all { $_ == 2 } values %colors;
        } elsif( is_chiral_trigonal_bipyramidal( $atom ) ) {
            next if scalar keys %colors == 5;
        } else {
            next if scalar keys %colors == 4;
        }

        delete $atom->{chirality};
        push @affected, $atom;
    }

    return @affected;
}

sub is_aromatic($)
{
    my( $atom ) = @_;
    return $atom->{symbol} ne ucfirst $atom->{symbol};
}

sub is_chiral($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        return exists $what->{chirality};
    } else {                    # Graph representing moiety
        return any { is_chiral( $_ ) } $what->vertices;
    }
}

sub is_chiral_allenal($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        return $what->{chirality} && $what->{chirality} =~ /^\@AL[12]$/;
    } else {                    # Graph representing moiety
        return any { is_chiral_allenal( $_ ) } $what->vertices;
    }
}

sub is_chiral_planar($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        return $what->{chirality} && $what->{chirality} =~ /^\@SP[123]$/;
    } else {                    # Graph representing moiety
        return any { is_chiral_planar( $_ ) } $what->vertices;
    }
}

sub is_chiral_tetrahedral($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        # CAVEAT: will fail for allenal configurations of @/@@ in raw mode
        return $what->{chirality} && $what->{chirality} =~ /^@@?$/;
    } else {                    # Graph representing moiety
        return any { is_chiral_tetrahedral( $_ ) } $what->vertices;
    }
}

sub is_chiral_trigonal_bipyramidal($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        return $what->{chirality} && $what->{chirality} =~ /^\@TB(1?[1-9]|20)$/;
    } else {                    # Graph representing moiety
        return any { is_chiral_trigonal_bipyramidal( $_ ) } $what->vertices;
    }
}

sub is_chiral_octahedral($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        return $what->{chirality} && $what->{chirality} =~ /^\@OH([1-9]|[12][0-9]|30)$/;
    } else {                    # Graph representing moiety
        return any { is_chiral_octahedral( $_ ) } $what->vertices;
    }
}

sub is_cis_trans_bond
{
    my( $moiety, $a, $b ) = @_;
    return $moiety->has_edge_attribute( $a, $b, 'bond' ) &&
           $moiety->get_edge_attribute( $a, $b, 'bond' ) =~ /^[\\\/]$/;
}

sub is_double_bond
{
    my( $moiety, $a, $b ) = @_;
    return $moiety->has_edge_attribute( $a, $b, 'bond' ) &&
           $moiety->get_edge_attribute( $a, $b, 'bond' ) eq '=';
}

# An atom is deemed to be a ring atom if any of its bonds is a ring bond.
sub is_ring_atom
{
    my( $moiety, $atom, $max_length ) = @_;
    return '' unless $moiety->degree( $atom ) > 1;
    return any { is_ring_bond( $moiety, $atom, $_, $max_length ) }
               $moiety->neighbours( $atom );
}

# A bond is deemed to be a ring bond if there is an alternative path
# joining its atoms not including the bond in consideration and this
# alternative path is not longer than 7 bonds. This is based on
# O'Boyle (2012) saying that Open Babel SMILES writer does not output
# cis/trans markers for double bonds in rings of size 8 or less due to
# them implicilty being cis bonds.
#
# If maximum ring size is given negative, ring size is not limited.
sub is_ring_bond
{
    my( $moiety, $a, $b, $max_length ) = @_;
    $max_length = 7 unless $max_length;

    # A couple of shortcuts to reduce the complexity
    return '' if any { $moiety->degree( $_ ) == 1 } ( $a, $b );
    return '' if scalar( $moiety->vertices ) > scalar( $moiety->edges );

    if( $max_length < 0 ) {
        # Due to the issue in Graph, bridges() returns strings instead of real objects.
        # Graph issue: https://github.com/graphviz-perl/Graph/issues/29
        my %vertices_by_name = map { $_ => $_ } $moiety->vertices;
        return none { ( $_->[0] == $a && $_->[1] == $b ) ||
                      ( $_->[0] == $b && $_->[1] == $a ) }
               map  { [ map { $vertices_by_name{$_} } @$_ ] } $moiety->bridges;
    }

    my $copy = $moiety->copy;
    $copy->delete_edge( $a, $b );

    my %distance = ( $a => 0 );
    my $record_length = sub {
        # Record number of bonds between $a and any other vertex
        my( $u, $v ) = @_;
        my @seen = grep { exists $distance{$_} } ( $u, $v );
        return '' if @seen != 1; # Can this be 0?

        my $seen = shift @seen;
        my( $unseen ) = grep { !exists $distance{$_} } ( $u, $v );
        $distance{$unseen} = $distance{$seen} + 1;
    };

    my $operations = {
        start     => sub { return $a },
        tree_edge => $record_length,
    };

    my $traversal = Graph::Traversal::BFS->new( $copy, %$operations );
    $traversal->bfs;

    # $distance{$b} is the distance in bonds. In 8-member rings adjacent
    # ring atoms have distance of 7 bonds.
    return exists $distance{$b} && $distance{$b} <= $max_length;
}

sub is_single_bond
{
    my( $moiety, $a, $b ) = @_;
    return !$moiety->has_edge_attribute( $a, $b, 'bond' ) ||
            $moiety->get_edge_attribute( $a, $b, 'bond' ) eq '-';
}

sub is_triple_bond
{
    my( $moiety, $a, $b ) = @_;
    return $moiety->has_edge_attribute( $a, $b, 'bond' ) &&
           $moiety->get_edge_attribute( $a, $b, 'bond' ) eq '#';
}

sub mirror($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        if( is_chiral_tetrahedral( $what ) ) {
            $what->{chirality} = $what->{chirality} eq '@' ? '@@' : '@';
        }
        if( is_chiral_allenal( $what ) ) {
            $what->{chirality} = $what->{chirality} eq '@AL1' ? '@AL2' : '@AL1';
        }
        # Square planar centers are not affected by mirroring, doing nothing
        if( is_chiral_trigonal_bipyramidal( $what ) ) {
            my $number = substr $what->{chirality}, 3;
            my $setting = $TB[$number-1];
            my $opposite = first { $TB[$_]->{axis}[0] == $setting->{axis}[0] &&
                                   $TB[$_]->{axis}[1] == $setting->{axis}[1] &&
                                   $TB[$_]->{order}   ne $setting->{order} }
                                 0..$#TB;
            $what->{chirality} = '@TB' . ($opposite + 1);
        }
        if( is_chiral_octahedral( $what ) ) {
            my $number = substr $what->{chirality}, 3;
            my $setting = $OH[$number-1];
            my $opposite = first { $OH[$_]->{shape}   eq $setting->{shape} &&
                                   $OH[$_]->{axis}[0] == $setting->{axis}[0] &&
                                   $OH[$_]->{axis}[1] == $setting->{axis}[1] &&
                                   $OH[$_]->{order}   ne $setting->{order} }
                                 0..$#OH;
            $what->{chirality} = '@OH' . ($opposite + 1);
        }
    } else {
        for ($what->vertices) {
            mirror( $_ );
        }
    }
}

sub toggle_cistrans($)
{
    return $_[0] eq '/' ? '\\' : '/';
}

sub valence($$)
{
    my( $moiety, $atom ) = @_;
    return ($atom->{hcount} ? $atom->{hcount} : 0) +
           sum0 map { exists $bond_symbol_to_order{$_}
                           ? $bond_symbol_to_order{$_}
                           : 1 }
                map { $moiety->has_edge_attribute( $atom, $_, 'bond' )
                           ? $moiety->get_edge_attribute( $atom, $_, 'bond' )
                           : 1 }
                    $moiety->neighbours( $atom );
}

# CAVEAT: requires output from non-raw parsing due issue similar to GH#2
sub _validate($@)
{
    my( $moiety, $color_sub ) = @_;

    for my $atom (sort { $a->{number} <=> $b->{number} } $moiety->vertices) {
        # TODO: AL chiral centers also have to be checked
        if( is_chiral_tetrahedral( $atom ) ) {
            if( $moiety->degree($atom) < 3 ) {
                # FIXME: there should be a strict mode to forbid lone pairs
                # FIXME: tetrahedral allenes are false-positives
                warn sprintf 'chiral center %s(%d) has %d bonds while ' .
                             'at least 3 is required' . "\n",
                             $atom->{symbol},
                             $atom->{number},
                             $moiety->degree($atom);
            } elsif( $moiety->degree($atom) == 4 && $color_sub ) {
                my %colors = map { ($color_sub->( $_ ) => 1) }
                                 $moiety->neighbours($atom);
                if( scalar keys %colors != 4 &&
                    !is_ring_atom( $moiety, $atom, scalar $moiety->edges ) ) {
                    warn sprintf 'tetrahedral chiral setting for %s(%d) ' .
                                 'is not needed as not all 4 neighbours ' .
                                 'are distinct' . "\n",
                                 $atom->{symbol},
                                 $atom->{number};
                }
            }
        }

        # Warn about unmarked tetrahedral chiral centers
        if( !is_chiral( $atom ) && $moiety->degree( $atom ) == 4 ) {
            my $color_sub_local = $color_sub;
            if( !$color_sub_local ) {
                $color_sub_local = sub { return $_[0]->{symbol} };
            }
            my %colors = map { ($color_sub_local->( $_ ) => 1) }
                             $moiety->neighbours($atom);
            if( scalar keys %colors == 4 ) {
                warn sprintf 'atom %s(%d) has 4 distinct neighbours, ' .
                             'but does not have a chiral setting' . "\n",
                             $atom->{symbol},
                             $atom->{number};
            }
        }
    }

    # FIXME: establish deterministic order
    for my $bond ($moiety->edges) {
        my( $A, $B ) = sort { $a->{number} <=> $b->{number} } @$bond;
        if( $A eq $B ) {
            warn sprintf 'atom %s(%d) has bond to itself' . "\n",
                         $A->{symbol},
                         $A->{number};
        }

        if( $moiety->has_edge_attribute( @$bond, 'bond' ) ) {
            my $bond_type = $moiety->get_edge_attribute( @$bond, 'bond' );
            if( $bond_type eq '=' ) {
                # Test cis/trans bonds
                # FIXME: Not sure how to check which definition belongs to
                # which of the double bonds. See COD entry 1547257.
                for my $atom (@$bond) {
                    my %bond_types = _neighbours_per_bond_type( $moiety,
                                                                $atom );
                    foreach ('/', '\\') {
                        if( $bond_types{$_} && @{$bond_types{$_}} > 1 ) {
                            warn sprintf 'atom %s(%d) has %d bonds of type \'%s\', ' .
                                         'cis/trans definitions must not conflict' . "\n",
                                         $atom->{symbol},
                                         $atom->{number},
                                         scalar @{$bond_types{$_}},
                                         $_;
                        }
                    }
                }
            } elsif( $bond_type =~ /^[\\\/]$/ ) {
                # Test if next to a double bond.
                # FIXME: Yields false-positives for delocalised bonds,
                # see COD entry 1501863.
                # FIXME: What about triple bond? See COD entry 4103591.
                my %bond_types;
                for my $atom (@$bond) {
                    my %bond_types_now = _neighbours_per_bond_type( $moiety,
                                                                    $atom );
                    for my $key (keys %bond_types_now) {
                        push @{$bond_types{$key}}, @{$bond_types_now{$key}};
                    }
                }
                if( !$bond_types{'='} ) {
                    warn sprintf 'cis/trans bond is defined between atoms ' .
                                 '%s(%d) and %s(%d), but neither of them ' .
                                 'is attached to a double bond' . "\n",
                                 $A->{symbol},
                                 $A->{number},
                                 $B->{symbol},
                                 $B->{number};
                }
            }
        }
    }

    # TODO: SP, TB, OH chiral centers
}

sub _neighbours_per_bond_type
{
    my( $moiety, $atom ) = @_;
    my %bond_types;
    for my $neighbour ($moiety->neighbours($atom)) {
        my $bond_type;
        if( $moiety->has_edge_attribute( $atom, $neighbour, 'bond' ) ) {
            $bond_type = $moiety->get_edge_attribute( $atom, $neighbour, 'bond' );
        } else {
            $bond_type = '';
        }
        if( $bond_type =~ /^[\\\/]$/ &&
            $atom->{number} > $neighbour->{number} ) {
            $bond_type = toggle_cistrans $bond_type;
        }
        push @{$bond_types{$bond_type}}, $neighbour;
    }
    return %bond_types;
}

1;

__END__

=pod

=head1 NAME

Chemistry::OpenSMILES - OpenSMILES format reader and writer

=head1 SYNOPSIS

    use Chemistry::OpenSMILES::Parser;

    my $parser = Chemistry::OpenSMILES::Parser->new;
    my @moieties = $parser->parse( 'C#C.c1ccccc1' );

    $\ = "\n";
    for my $moiety (@moieties) {
        #  $moiety is a Graph::Undirected object
        print scalar $moiety->vertices;
        print scalar $moiety->edges;
    }

    use Chemistry::OpenSMILES::Writer qw(write_SMILES);

    print write_SMILES( \@moieties );

=head1 DESCRIPTION

Chemistry::OpenSMILES provides support for SMILES chemical identifiers
conforming to OpenSMILES v1.0 specification
(L<http://opensmiles.org/opensmiles.html>).

Chemistry::OpenSMILES::Parser reads in SMILES strings and returns them
parsed to arrays of L<Graph::Undirected|Graph::Undirected> objects. Each
atom is represented by a hash.

Chemistry::OpenSMILES::Writer performs the inverse operation. Generated
SMILES strings are by no means optimal.

=head2 Molecular graph

Disconnected parts of a compound are represented as separate
L<Graph::Undirected|Graph::Undirected> objects. Atoms are represented
as vertices, and bonds are represented as edges.

=head3 Atoms

Atoms, or vertices of a molecular graph, are represented as hash
references:

    {
        "symbol"    => "C",
        "isotope"   => 13,
        "chirality" => "@@",
        "hcount"    => 3,
        "charge"    => 1,
        "class"     => 0,
        "number"    => 0,
    }

Except for C<symbol>, C<class> and C<number>, all keys of hash are
optional. Per OpenSMILES specification, default values for C<hcount>
and C<class> are 0.

For chiral atoms, the order of its neighbours in input is preserved in
an array added as value for C<chirality_neighbours> key of the atom hash.

=head3 Bonds

Bonds, or edges of a molecular graph, rely completely on
L<Graph::Undirected|Graph::Undirected> internal representation. Bond
orders other than single (C<->, which is also a default) are represented
as values of edge attribute C<bond>. They correspond to the symbols used
in OpenSMILES specification.

=head2 Options

C<parse> accepts the following options for key-value pairs in an
anonymous hash for its second parameter:

=over

=item C<max_hydrogen_count_digits>

In OpenSMILES specification the number of attached hydrogen atoms for
atoms in square brackets is limited to 9. IUPAC SMILES+ has increased
this number to 99. With the value of C<max_hydrogen_count_digits> the
parser could be instructed to allow other than 1 digit for attached
hydrogen count.

=item C<raw>

With C<raw> set to anything evaluating to true, the parser will not
convert neither implicit nor explicit hydrogen atoms in square brackets
to atom hashes of their own. Moreover, it will not attempt to unify the
representations of chirality. It should be noted, though, that many of
subroutines of Chemistry::OpenSMILES expect non-raw data structures,
thus processing raw output may produce distorted results. In particular,
C<write_SMILES()> calls from
L<Chemistry::OpenSMILES::Writer|Chemistry::OpenSMILES::Writer> have to
be instructed to expect raw data structure:

    write_SMILES( \@moieties, { raw => 1 } );

=back

=head1 CAVEATS

Element symbols in square brackets are not limited to the ones known to
chemistry. Currently any single or two-letter symbol is allowed.

Deprecated charge notations (C<--> and C<++>) are supported.

OpenSMILES specification mandates a strict order of ring bonds and
branches:

    branched_atom ::= atom ringbond* branch*

Chemistry::OpenSMILES::Parser supports both the mandated, and inverted
structure, where ring bonds follow branch descriptions.

Whitespace is not supported yet. SMILES descriptors must be cleaned of
it before attempting reading with Chemistry::OpenSMILES::Parser.

The derivation of implicit hydrogen counts for aromatic atoms is not
unambiguously defined in the OpenSMILES specification. Thus only
aromatic carbon is accounted for as if having valence of 3.

Chiral atoms with three neighbours are interpreted as having a lone
pair of electrons as the fourth chiral neighbour. The lone pair is
always understood as being the second in the order of neighbour
enumeration, except when the atom with the lone pair starts a chain. In
that case lone pair is the first.

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut
