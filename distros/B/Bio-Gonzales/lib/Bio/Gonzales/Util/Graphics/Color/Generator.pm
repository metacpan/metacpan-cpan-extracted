package Bio::Gonzales::Util::Graphics::Color::Generator;

use Mouse;
use Data::Dumper;

use warnings;
use strict;
use Carp;
use List::MoreUtils qw/zip/;

use 5.010;
use SVG;
our $VERSION = '0.0546'; # VERSION

=head1 NAME

Bio::Gonzales::Util::Common::Visual::Color::Generator - generate distinguishable colors in RGB format

=head1 SYNOPSIS

    use Bio::Gonzales::Util::Common::Visual::Color::Generator;

    my $generator = Bio::Gonzales::Util::Common::Visual::Color::Generator->new;
    my $colors = $generator->generate(30); #number of colors as argument

    for my $c (@{$colors}) {
        say "R: $c->[0], G: $c->[1], B: $c->[2]";
    }

=head1 SUBROUTINES/METHODS
=cut

has _patterns => (
    is      => 'rw',
    default => sub {
        [ [0], [1], [2], [ 0, 1 ], [ 0, 2 ], [ 1, 2 ], ];
    }
);

=head2 generate($number_of_colors)

Generate array of a given number color triplets.

=cut

sub generate {
    my ( $self, $number ) = @_;

    my $start = 255;

    my @colors;
    for ( my $i = 0; $i < $number; $i++ ) {
        if ( $i % 6 == 0 && $i > 0 ) {
            if ( $i % 18 == 0 ) {
                $start += 2 * int($start);
            } else {
                $start = int( ( $start + 1 ) / 2 );
            }
        }

        my @color = ( 0, 0, 0 );
        map { $color[$_] = $start } @{ $self->_patterns->[ $i % 6 ] };
        push @colors, \@color;
    }
    return \@colors;
}

sub generate_as_hex {
    my ( $self, $number ) = @_;

    my $colors = $self->generate($number);

    my @colors = map { "#" . sprintf "%02x%02x%02x", @{$_} } @{$colors};

    return @colors;
}

=head2 generate_as_string($number_of_colors)

Generate string "RRR GGG BBB" version from a given number of colors

=cut

sub generate_as_string {
    my ( $self, $number ) = @_;

    my $colors = $self->generate($number);

    my @colors = map { join " ", @{$_} } @{$colors};
    return @colors;
}

sub create_legend {
    my ( $self, $args ) = @_;

    my $a = $args;
    if ( ref $args eq 'ARRAY' ) {
        my @colors = $self->generate_as_hex( scalar @{$args} );
        $a = { zip @{$args}, @colors };
    }

    my $num_elements = keys %{$a};

    my $height = ( 30 + 10 ) * $num_elements - 10;
    my $width  = 500;
    my $svg    = SVG->new( width => $width, height => $height );
    my $i      = 0;
    while ( my ( $group_id, $color ) = each %{$a} ) {
        my $y_offset = $i * ( 30 + 10 );
        my $text1 = $svg->text( id => "text_$i", x => 45, y => $y_offset + 15 )->cdata($group_id);
        my $tag = $svg->rectangle( x => 0, y => $y_offset, width => 40, height => 30, id => "rect_$i", fill => $color );
        $i++;

    }
    return $svg->xmlify;
}

1;
__END__

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
