package App::AsciiChart;
use 5.008001;
use strict;
use warnings;
use List::Util qw(min max);

our $VERSION = "0.03";

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub plot {
    my $self = shift;
    my ($series) = @_;

    my $min = min @$series;
    my $max = max @$series;

    my $padding = length $max;

    my $range = abs( $min - $max );

    my $height = $range;
    my $ratio  = $height / $range;

    my $min2 = int( $min * $ratio );
    my $max2 = int( $max * $ratio );
    my $rows = abs( $max2 - $min2 );

    my $result = [];

    for ( 0 .. $rows ) {
        push @$result, [ '.', map { '.' } @$series ];
    }

    for my $row ( 0 .. $rows ) {
        $result->[$row]->[0] =
          ( sprintf "%${padding}s", $max2 - $ratio * $row )
          . ( $row == $rows - int( $series->[0] * $ratio ) + $min2
            ? '┼'
            : '┤' );

        for ( my $x = 0 ; $x < @$series - 1 ; $x++ ) {
            my $y0 = int( $series->[$x] * $ratio ) - $min2;
            my $y1 = int( $series->[ $x + 1 ] * $ratio ) - $min2;

            if ( $y0 == $y1 ) {
                $result->[ $rows - $y0 ]->[ $x + 1 ] = '─';
            }
            else {
                $result->[ $rows - $y1 ]->[ $x + 1 ] =
                  ( $y0 > $y1 ) ? '╰' : '╭';
                $result->[ $rows - $y0 ]->[ $x + 1 ] =
                  ( $y0 > $y1 ) ? '╮' : '╯';

                my $from = min( $y0, $y1 );
                my $to = max( $y0, $y1 );

                for ( my $y = $from + 1 ; $y < $to ; $y++ ) {
                    $result->[ $rows - $y ]->[ $x + 1 ] = '│';
                }
            }
        }
    }

    my $plot = '';

    foreach my $line (@$result) {
        $plot .= join '', @$line;
        $plot .= "\n";
    }

    return $plot;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::AsciiChart - Simple Ascii Chart

=head1 SYNOPSIS

    use App::AsciiChart;

    App::AsciiChart->new->plot([1, 5, 3, 9, 10, 12]);

=head1 DESCRIPTION

App::AsciiChart is a port to Perl of L<https://github.com/kroitor/asciichart> project.

    12| ....╭.
    11| ....│.
    10| ...╭╯.
     9| ..╭╯..
     8| ..│...
     7| ..│...
     6| ..│...
     5| ╭╮│...
     4| │││...
     3| │╰╯...
     2| │.....
     1| ╯.....

There is also a command line script L<asciichart>.

=head1 LICENSE

Copyright (C) Viacheslav Tykhanovskyi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Viacheslav Tykhanovskyi E<lt>viacheslav.t@gmail.comE<gt>

=cut
