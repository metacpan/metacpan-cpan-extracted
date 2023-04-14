package Data::Password::zxcvbn::AuthorTools::BuildAdjacencyGraphs;
use v5.26;
use Types::Common::String qw(NonEmptySimpleStr NonEmptyStr);
use Types::Standard qw(ArrayRef Dict Bool);
use List::Util qw(uniq);
use Moo;
use namespace::clean;
our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: class to generate C<Data::Password::zxcvbn::*::AdjacencyGraph>

with 'Data::Password::zxcvbn::AuthorTools::PackageWriter';


has layouts => (
    is => 'ro',
    isa => ArrayRef[
        Dict[
            name => NonEmptySimpleStr,
            layout => NonEmptyStr,
            slanted => Bool,
        ],
    ],
    required => 1,
);


has '+package_abstract' => (
    default => 'adjacency graphs for common keyboards',
);

# returns the six adjacent coordinates on a standard keyboard, where
# each row is slanted to the right from the last. adjacencies are
# clockwise, starting with key to the left, then two keys above, then
# right key, then two keys below. (that is, only near-diagonal keys
# are adjacent, so g's coordinate is adjacent to those of t,y,b,v, but
# not those of r,u,n,c.)
sub _get_slanted_adjacent_coords {
    my ($x, $y) = @_;
    return (
        [$x-1,$y], [$x, $y-1], [$x+1, $y-1],
        [$x+1, $y], [$x, $y+1], [$x-1, $y+1],
    );
}

# returns the nine clockwise adjacent coordinates on a keypad, where
# each row is vert aligned.
sub _get_aligned_adjacent_coords {
    my ($x, $y) = @_;
    return (
        [$x-1, $y], [$x-1, $y-1], [$x, $y-1], [$x+1, $y-1],
        [$x+1, $y], [$x+1, $y+1], [$x, $y+1], [$x-1, $y+1],
    )
}

sub _average_degree {
    my ($graph) = @_;

    my $average = 0;
    for my $neighbors (values %{$graph}) {
        $average += grep {defined} @{$neighbors};
    }
    $average /= scalar(keys %{$graph});
    return $average;
}

sub _build_position_table {
    my ($self,$layout_str,$slanted) = @_;

    my %position_table;
    my @tokens = grep {length($_)} split /\s+/, $layout_str;
    my $token_length = length($tokens[0]);

    grep { length($_) != $token_length } @tokens
        and die "token length mismatch:\n$layout_str\n";

    my $x_unit = $token_length + 1;
    my $y=0;
    for my $line (split /\n/,$layout_str) {
        my $slant = $slanted ? $y - 1 : 0;
        for my $token (split /\s+/,$line) {
            next unless length($token);
            my $x = int((index($line,$token) - $slant) / $x_unit);
            $position_table{$x}->{$y} = $token;
        }
        ++$y;
    }

    return \%position_table;
}

# builds an adjacency graph as a dictionary: {character:
# [adjacent_characters]}.  adjacent characters occur in a clockwise
# order.
#
# for example:
#
# * on qwerty layout, 'g' maps to ['fF', 'tT', 'yY', 'hH', 'bB', 'vV']
# * on keypad layout, '7' maps to [undef, undef, undef, '=', '8', '5',
# '4', undef]
sub _build_graph {
    my ($self, $layout_str, $slanted) = @_;

    my $position_table = $self->_build_position_table(
        $layout_str, $slanted,
    );

    my $adjacency_function = $slanted
        ? \&_get_slanted_adjacent_coords
        : \&_get_aligned_adjacent_coords;

    my %adjacency_graph;
    for my $x (sort keys %{$position_table}) {
        my $column = $position_table->{$x};
        for my $y (sort keys %{$column}) {
            my $chars = $column->{$y};

            # that `uniq` is needed to support keys without shifted
            # variant; such keys must be written as `xx` otherwise
            # _build_position_table will ignore them, but we should
            # not consider them as producing 2 separate identical
            # characters, otherwise we get the adjacent nodes twice
            for my $char (uniq split //,$chars) {
                for my $coords ($adjacency_function->($x,$y)) {
                    push @{$adjacency_graph{$char}},
                        $position_table->{$coords->[0]}->{$coords->[1]};
                }
            }
        }
    }

    return \%adjacency_graph;
}


sub generate {
    my ($self) = @_;

    my %all_graphs;
    for my $layout (@{$self->layouts}) {
        my $graph = $self->_build_graph($layout->{layout}, $layout->{slanted});

        $all_graphs{ $layout->{name} } = {
            keys => $graph,
            average_degree => _average_degree($graph),
            starting_positions => scalar keys %{$graph},
        };
    }

    $self->write_out(\%all_graphs);
}


sub hash_variable_name { 'graphs' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Password::zxcvbn::AuthorTools::BuildAdjacencyGraphs - class to generate C<Data::Password::zxcvbn::*::AdjacencyGraph>

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

In your distribution's F<maint/build-keyboard-adjacency-graphs>:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Data::Password::zxcvbn::AuthorTools::BuildAdjacencyGraphs;

    Data::Password::zxcvbn::AuthorTools::BuildAdjacencyGraphs->new({
        layouts => [
            { name => 'keypad', layout => <<'EOK', slanted => 0 },
      / * -
    7 8 9 +
    4 5 6
    1 2 3
      0 .
    EOK
            { name => 'qwerty', layout => <<'EOK', slanted => 1 },
    `~ 1! 2@ 3# 4$ 5% 6^ 7& 8* 9( 0) -_ =+
        qQ wW eE rR tT yY uU iI oO pP [{ ]} \|
         aA sS dD fF gG hH jJ kK lL ;: '"
          zZ xX cC vV bB nN mM ,< .> /?
    EOK
        ],
        package_name => 'Data::Password::zxcvbn::AdjacencyGraph::MyThing',
        package_abstract => 'adjacency graphs for my keyboards',
        package_description => <<'EOF',
    This is a data file used by L<<
    C<Data::Password::zxcvbn::Match::Spatial> >>, and is generated by
    the L<< C<build-keyboard-adjacency-graphs>|...>> program when
    building the distribution.
    EOF
    })->generate;

(a skeleton of such a file is generated when running C<dzil new -P
zxcvbn Data::Password::zxcvbn::MyThing>)

=head1 ATTRIBUTES

=head2 C<layouts>

Arrayref of dictionaries (C<name>, C<layout>, C<slanted>) defining the
keyboards to analyse.

=head2 C<output_dir>

Where to write the generated package. Defaults to C<$ARGV[1]> or
F<lib/>; this supports running the
F<main/build-keyboard-adjacency-graphs> script manually and via the
F<dist.ini> file.

=head2 C<package_name>

Name of the package to generate, required. Should start with
C<Data::Password::zxcvbn::AdjacencyGraph::>

=head2 C<package_version>

Version of the package. Defaults to C<$ARGV[0]> or C<undef>; this
supports running the F<main/build-keyboard-adjacency-graphs> script
manually and via the F<dist.ini> file.

=head2 C<package_abstract>

Abstract of the package, defaults to "adjacency graphs for common
keyboards".

=head2 C<package_description>

Description of the package, required.

=head1 METHODS

=head2 C<generate>

Writes out the package.

=for Pod::Coverage hash_variable_name

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
