package Chemistry::OpenSMILES;

use strict;
use warnings;
use 5.0100;

# ABSTRACT: OpenSMILES format reader and writer
our $VERSION = '0.5.1'; # VERSION

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    clean_chiral_centers
    is_aromatic
    is_chiral
    mirror
);

use List::Util qw(any);

sub is_chiral($);
sub is_chiral_tetrahedral($);
sub mirror($);

# Removes chiral setting from tetrahedral chiral centers with less than
# four distinct neighbours. Returns the affected atoms.
#
# CAVEAT: disregards anomers
# TODO: check other chiral centers
sub clean_chiral_centers($$)
{
    my( $moiety, $color_sub ) = @_;

    my @affected;
    for my $atom ($moiety->vertices) {
        next unless is_chiral_tetrahedral( $atom );

        my $hcount = exists $atom->{hcount} ? $atom->{hcount} : 0;
        next if $moiety->degree($atom) + $hcount != 4;

        my %colors = map { ($color_sub->( $_ ) => 1) }
                         $moiety->neighbours($atom),
                         ( { symbol => 'H' } ) x $hcount;
        next if scalar keys %colors == 4;
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

sub is_chiral_tetrahedral($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        return $what->{chirality} && $what->{chirality} =~ /^@@?$/
    } else {                    # Graph representing moiety
        return any { is_chiral_tetrahedral( $_ ) } $what->vertices;
    }
}

sub mirror($)
{
    my( $what ) = @_;
    if( ref $what eq 'HASH' ) { # Single atom
        # FIXME: currently dealing only with tetrahedral chiral centers
        if( is_chiral_tetrahedral( $what ) ) {
            $what->{chirality} = $what->{chirality} eq '@' ? '@@' : '@';
        }
    } else {
        for ($what->vertices) {
            mirror( $_ );
        }
    }
}

# CAVEAT: requires output from non-raw parsing due issue similar to GH#2
sub _validate($@)
{
    my( $moiety, $color_sub ) = @_;

    for my $atom (sort { $a->{number} <=> $b->{number} } $moiety->vertices) {
        # TODO: AL chiral centers also have to be checked
        if( is_chiral_tetrahedral( $atom ) ) {
            if( $moiety->degree($atom) < 4 ) {
                # FIXME: tetrahedral allenes are false-positives
                warn sprintf 'chiral center %s(%d) has %d bonds while ' .
                             'at least 4 is required' . "\n",
                             $atom->{symbol},
                             $atom->{number},
                             $moiety->degree($atom);
            } elsif( $moiety->degree($atom) == 4 && $color_sub ) {
                my %colors = map { ($color_sub->( $_ ) => 1) }
                                 $moiety->neighbours($atom);
                if( scalar keys %colors != 4 ) {
                    # FIXME: anomers are false-positives, see COD entry
                    # 7111036
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
            $bond_type = $bond_type eq '\\' ? '/' : '\\';
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
optional. Per OpenSMIILES specification, default values for C<hcount>
and C<class> are 0.

=head3 Bonds

Bonds, or edges of a molecular graph, rely completely on
L<Graph::Undirected|Graph::Undirected> internal representation. Bond
orders other than single (C<->, which is also a default) are represented
as values of edge attribute C<bond>. They correspond to the symbols used
in OpenSMILES specification.

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

=head1 SEE ALSO

perl(1)

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut
