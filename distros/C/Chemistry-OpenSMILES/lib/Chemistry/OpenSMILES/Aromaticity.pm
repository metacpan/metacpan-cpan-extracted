package Chemistry::OpenSMILES::Aromaticity;

use strict;
use warnings;

# ABSTRACT: Aromaticity handling routines
our $VERSION = '0.11.0'; # VERSION

use Chemistry::OpenSMILES qw(
    is_aromatic
    is_double_bond
    is_single_bond
);
use Graph::Traversal::DFS;
use List::Util qw( all );

=head1 NAME

Chemistry::OpenSMILES::Aromaticity - Aromaticity handling routines

=head1 DESCRIPTION

Chemistry::OpenSMILES::Aromaticity encodes some aromaticity handling
subroutines for aromatisation and kekulisation. Both implementations are
experimental, handle only some specific cases and are neither stable nor
bug-free, thus should be used with caution.

=cut

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    aromatise
    electron_cycles
    kekulise
);

=head1 METHODS

=over 4

=item aromatise( $moiety )

Mark electron cycles as aromatic.

=cut

sub aromatise
{
    my( $moiety ) = @_;

    my @electron_cycles = electron_cycles( $moiety );
    for my $cycle (@electron_cycles) {
        for my $i (0..$#$cycle) {
            # Set bond to aromatic
            $moiety->set_edge_attribute( $cycle->[$i],
                                         $cycle->[($i + 1) % scalar @$cycle],
                                         'bond',
                                         ':' );
            # Set atom to aromatic
            if( $cycle->[$i]{symbol} =~ /^([BCNOPS]|Se|As)$/ ) {
                $cycle->[$i]{symbol} = lcfirst $cycle->[$i]{symbol};
            }
        }
    }
}

=item kekulise( $moiety )

Find nonfused even-length aromatic cycles consisting only of B, C, N, P, S
and mark them with aliterating single and double bonds.

=cut

sub kekulise
{
    my( $moiety ) = @_;

    my $aromatic_only = $moiety->copy_graph;
    $aromatic_only->delete_vertices( grep { !is_aromatic $_ }
                                          $aromatic_only->vertices );

    my @components;
    my $get_root = sub {
        my( $self, $unseen ) = @_;
        my( $next ) = sort { $unseen->{$a}{number} <=> $unseen->{$b}{number} }
                           keys %$unseen;
        return unless defined $next;

        push @components, [];
        return $unseen->{$next};
    };

    my $operations = {
        first_root => $get_root,
        next_root  => $get_root,
        pre => sub { push @{$components[-1]}, $_[0] },
    };
    my $traversal = Graph::Traversal::DFS->new( $aromatic_only, %$operations );
    $traversal->dfs;

    for my $component (@components) {
        # Taking only simple even-length cycles into consideration
        next unless all { $aromatic_only->degree( $_ ) == 2 } @$component;
        next unless all { $moiety->degree( $_ ) <= 3 }   @$component;
        next unless all { $_->{symbol} =~ /^[BCNPS]$/i } @$component;
        next if @$component % 2;

        my( $first  ) = sort { $a->{number} <=> $b->{number} } @$component;
        my( $second ) = sort { $a->{number} <=> $b->{number} }
                             $aromatic_only->neighbours( $first );
        my $n = 0;
        while( $n < @$component ) {
            $first->{symbol} = ucfirst $first->{symbol};
            if( $n % 2 ) {
                $moiety->set_edge_attribute( $first, $second, 'bond', '=' );
            } else {
                $moiety->delete_edge_attribute( $first, $second, 'bond' );
            }
            ( $first, $second ) =
                ( $second, grep { $_ ne $first } $aromatic_only->neighbours( $second ) );
            $n++;
        }
    }
}

=item electron_cycles( $moiety )

Find electron cycles according to "Finding Electron Cycles" algorithm from
L<https://depth-first.com/articles/2021/06/30/writing-aromatic-smiles/>.
Use with caution: the implementation is experimental.

=cut

sub electron_cycles
{
    my( $moiety ) = @_;

    my @cycles;
    for my $start ($moiety->vertices) {
        my %seen;
        my %prev;
        my $operations = {
            start      => sub { return $start },
            pre        => sub { $seen{$_[0]} = 1 },
            pre_edge   => sub {
                my( $u, $v ) = @_;
                ( $u, $v ) = ( $v, $u ) if $seen{$v};
                $prev{$v} = $u;
            },
            non_tree_edge => sub {
                my( $u, $v ) = @_;
                if( $u == $start || $v == $start ) {
                    ( $u, $v ) = ( $v, $u ) if $v == $start;
                    my $current = $v;
                    my $prev_bond_is_single;
                    my $cycle_is_alterating = 1;
                    my @cycle = ( $u );
                    while( $prev{$current} ) {
                        if( ( !defined $prev_bond_is_single && (
                                is_single_bond( $moiety, $current, $prev{$current} ) ||
                                is_double_bond( $moiety, $current, $prev{$current} ) ) ) ||
                            (  $prev_bond_is_single && is_double_bond( $moiety, $current, $prev{$current} ) ) ||
                            ( !$prev_bond_is_single && is_single_bond( $moiety, $current, $prev{$current} ) ) ) {
                            # Logic is inverted here as $prev_bond_is_single is
                            # inverted after the conditional.
                            $prev_bond_is_single = !is_single_bond( $moiety, $current, $prev{$current} );
                            push @cycle, $current;
                            $current = $prev{$current};
                        } else {
                            $cycle_is_alterating = 0;
                            last;
                        }
                        last unless $cycle_is_alterating;
                        $prev_bond_is_single = 1 - $prev_bond_is_single;
                    }
                    push @cycles, \@cycle if $cycle_is_alterating;
                }
            },
        };

        my $traversal = Graph::Traversal::DFS->new( $moiety, %$operations );
        $traversal->dfs;
    }

    my %unique;
    for (@cycles) {
        $unique{join '', sort @$_} = $_;
    }
    return values %unique;
}

=back

=cut

1;
