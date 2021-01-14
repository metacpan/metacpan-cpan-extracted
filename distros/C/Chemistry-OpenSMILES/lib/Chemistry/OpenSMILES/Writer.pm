package Chemistry::OpenSMILES::Writer;

use strict;
use warnings;

use Chemistry::OpenSMILES qw(is_aromatic);
use Graph::Traversal::DFS;

# ABSTRACT: OpenSMILES format writer
our $VERSION = '0.4.1'; # VERSION

sub write
{
    my( $what, $order_sub ) = @_;

    my @moieties = ref $what eq 'ARRAY' ? @$what : ( $what );
    my @components;

    $order_sub = \&_order unless $order_sub;

    for my $graph (@moieties) {
        my @symbols;
        my %vertex_symbols;
        my $nrings = 0;
        my %seen_rings;

        my $rings = {};

        my $operations = {
            tree_edge     => sub { push @symbols, _tree_edge( @_ ) },
            non_tree_edge => sub { my @sorted = sort { $a <=> $b }
                                                     map { $vertex_symbols{$_} }
                                                         @_[0..1];
                                   $rings->{$sorted[0]}{$sorted[1]} =
                                        _depict_bond( @_[0..1], $graph ); },

            pre  => sub { push @symbols, _pre_vertex( @_ );
                          $vertex_symbols{$_[0]} = $#symbols },
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
                    $symbols[$j] .= $rings->{$i}{$j} .
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

sub _tree_edge
{
    my( $u, $v, $self ) = @_;

    return '(' . _depict_bond( $u, $v, $self->graph );
}

sub _pre_vertex
{
    my( $vertex, $self ) = @_;

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

    # CAVEAT: '/' and '\' bonds are problematic
    return $graph->has_edge_attribute( $u, $v, 'bond' )
         ? $graph->get_edge_attribute( $u, $v, 'bond' )
         : is_aromatic $u && is_aromatic $v ? '-' : '';
}

sub _order
{
    my( $vertices ) = @_;
    my @sorted = sort { $vertices->{$a}{number} <=>
                        $vertices->{$b}{number} } keys %$vertices;
    return $vertices->{shift @sorted};
}

1;
