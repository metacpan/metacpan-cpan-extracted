package Chemistry::OpenSMILES::Writer;

use strict;
use warnings;

use Chemistry::OpenSMILES qw(is_aromatic);
use Chemistry::OpenSMILES::Parser;
use Graph::Traversal::DFS;

# ABSTRACT: OpenSMILES format writer
our $VERSION = '0.4.6'; # VERSION

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    write_SMILES
);

sub write_SMILES
{
    my( $what, $order_sub ) = @_;

    if( ref $what eq 'HASH' ) {
        # subroutine will also accept and properly represent a single
        # atom:
        return _pre_vertex( $what );
    }

    my @moieties = ref $what eq 'ARRAY' ? @$what : ( $what );
    my @components;

    $order_sub = \&_order unless $order_sub;

    for my $graph (@moieties) {
        my @symbols;
        my %vertex_symbols;
        my $nrings = 0;
        my %seen_rings;
        my @chiral;

        my $rings = {};

        my $operations = {
            tree_edge     => sub { if( $vertex_symbols{$_[1]} ) {
                                       @_ = ( $_[1], $_[0], $_[2] );
                                   }
                                   push @symbols, _tree_edge( @_ ) },

            non_tree_edge => sub { my @sorted = sort { $vertex_symbols{$a} <=>
                                                       $vertex_symbols{$b} }
                                                     @_[0..1];
                                   $rings->{$vertex_symbols{$sorted[0]}}
                                           {$vertex_symbols{$sorted[1]}} =
                                        _depict_bond( @sorted, $graph ); },

            pre  => sub { my( $vertex, $dfs ) = @_;
                          if( $vertex->{chirality} &&
                              $vertex->{chirality} =~ /^@@?$/ &&
                              $dfs->graph->degree( $vertex ) == 4 ) {
                              push @chiral, $vertex;
                          }
                          push @symbols,
                          _pre_vertex( { map { $_ => $vertex->{$_} }
                                         grep { $_ ne 'chirality' }
                                         keys %$vertex } );
                          $vertex_symbols{$vertex} = $#symbols },

            post => sub { push @symbols, ')' },
        };

        if( $order_sub ) {
            $operations->{first_root} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
            $operations->{next_successor} =
                sub { return $order_sub->( $_[1], $_[0]->graph ) };
        }

        my $traversal = Graph::Traversal::DFS->new( $graph, %$operations );
        $traversal->dfs;

        next unless @symbols;
        pop @symbols;

        # Dealing with chirality
        for my $atom (@chiral) {
            my @neighbours = map { $_->{number} }
                             sort { $vertex_symbols{$a} <=>
                                    $vertex_symbols{$b} }
                             $graph->neighbours($atom);
            my $chirality_now = _tetrahedral_chirality( $atom->{chirality},
                                                        @neighbours );
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
    my( $vertex ) = @_;

    my $atom = $vertex->{symbol};
    my $is_simple = $atom =~ /^[bcnosp]$/i ||
                    $atom =~ /^(F|Cl|Br|I|\*)$/;

    if( exists $vertex->{isotope} ) {
        $atom = $vertex->{isotope} . $atom;
        $is_simple = 0;
    }

    if( exists $vertex->{chirality} ) {
        $atom .= $vertex->{chirality};
        $is_simple = 0;
    }

    if( $vertex->{hcount} ) { # if non-zero
        $atom .= 'H' . ($vertex->{hcount} == 1 ? '' : $vertex->{hcount});
        $is_simple = 0;
    }

    if( $vertex->{charge} ) { # if non-zero
        $atom .= ($vertex->{charge} > 0 ? '+' : '') . $vertex->{charge};
        $atom =~ s/([-+])1$/$1/;
        $is_simple = 0;
    }

    if( $vertex->{class} ) { # if non-zero
        $atom .= ':' . $vertex->{class};
        $is_simple = 0;
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
    return $bond eq '/' ? '\\' : '/';
}

# Invert the tetrahedral chirality sign if the order of attachments
# has changed from clockwise to counter-clockwise and vice versa.
sub _tetrahedral_chirality
{
    my( $chirality, @numbers ) = @_;

    # Translating the numbers to range of 0..3
    my @indices = sort { $numbers[$a] <=> $numbers[$b] } 0..3;
    foreach (0..3) {
        $numbers[$indices[$_]] = $_;
    }

    # First attachment is written on left hand side of the chiral
    # center, here it is called $direction
    my $direction = shift @numbers;

    # Cyclically sorting the rest of the attachments
    while( $numbers[0] > $numbers[1] || $numbers[0] > $numbers[2] ) {
        push @numbers, shift @numbers;
    }

    # Checking whether the direction has been changed
    if( ($direction == 0 && $numbers[1] == 2) ||
        ($direction == 1 && $numbers[1] == 3) ||
        ($direction == 2 && $numbers[1] == 1) ||
        ($direction == 3 && $numbers[1] == 2) ) {
        return $chirality;
    } else {
        return $chirality eq '@' ? '@@' : '@';
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
