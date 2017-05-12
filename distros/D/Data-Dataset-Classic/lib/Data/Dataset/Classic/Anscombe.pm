package Data::Dataset::Classic::Anscombe;

use strict;
use warnings;
use utf8;

use Data::Dataset::Classic;

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Anscombe classic dataset

my $dataset = { 'x1' => [ 10.0, 8.0,  13.0,  9.0,  11.0, 14.0, 6.0,  4.0,   12.0,  7.0,  5.0 ],
                'x2' => [ 10.0, 8.0,  13.0,  9.0,  11.0, 14.0, 6.0,  4.0,   12.0,  7.0,  5.0 ],
                'x3' => [ 10.0, 8.0,  13.0,  9.0,  11.0, 14.0, 6.0,  4.0,   12.0,  7.0,  5.0 ],
                'x4' => [ 8.0,  8.0,  8.0,   8.0,  8.0,  8.0,  8.0,  19.0,  8.0,   8.0,  8.0 ],
                'y1' => [ 8.04, 6.95, 7.58,  8.81, 8.33, 9.96, 7.24, 4.26,  10.84, 4.82, 5.68 ],
                'y2' => [ 9.14, 8.14, 8.74,  8.77, 9.26, 8.10, 6.13, 3.10,  9.13,  7.26, 4.74 ],
                'y3' => [ 7.46, 6.77, 12.74, 7.11, 7.81, 8.84, 6.08, 5.39,  8.15,  6.42, 5.73 ],
                'y4' => [ 6.58, 5.76, 7.71,  8.84, 8.47, 7.04, 5.25, 12.50, 5.56,  7.91, 6.89 ],
};

sub get {
    return Data::Dataset::Classic::_adapt( $dataset, @_ );
}

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Dataset::Classic::Anscombe - Anscombe classic dataset

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Data::Dataset::Classic::Anscombe;
 use Chart::Plotly qw(show_plot);
 use Chart::Plotly::Plot;
 use Chart::Plotly::Trace::Scatter;
 
 my $anscombe_quartet = Data::Dataset::Classic::Anscombe::get();
 
 my $anscombe_plot = Chart::Plotly::Plot->new(layout => {
 	xaxis => {
 		domain => [0, 0.45]
 		},
 	yaxis => {
 		domain => [0.55, 1]
 		},
 	yaxis2 => {
 		domain => [0.55, 1],
 		anchor => 'x2'
 		},
 	xaxis2 => {
 		domain => [0.55, 1]
 		},
 	xaxis3 => {
 		domain => [0, 0.45],
 		anchor => 'y3'
 		},
 	yaxis3 => {
 		domain => [0, 0.45]
 		},
 	yaxis4 => {
 		anchor => 'x4',
 		domain => [0, 0.45],
 		},
 	xaxis4 => {
 		domain => [0.55, 1],
 		anchor => 'y4'
 		}
 });
 
 my $first_anscombe = Chart::Plotly::Trace::Scatter->new( 
 	x => $anscombe_quartet->{'x1'},
 	y => $anscombe_quartet->{'y1'},
 	mode => 'markers',
 	marker => {size => 20},
 	name => 'I'
 );
 $anscombe_plot->add_trace($first_anscombe);
 my $second_anscombe = Chart::Plotly::Trace::Scatter->new( 
 	x => $anscombe_quartet->{'x2'},
 	y => $anscombe_quartet->{'y2'},
 	xaxis => 'x2',
 	yaxis => 'y2',
 	mode => 'markers',
 	marker => {size => 20},
 	name => 'II'
 );
 $anscombe_plot->add_trace($second_anscombe);
 my $third_anscombe = Chart::Plotly::Trace::Scatter->new( 
 	x => $anscombe_quartet->{'x3'},
 	y => $anscombe_quartet->{'y3'},
 	xaxis => 'x3',
 	yaxis => 'y3',
 	mode => 'markers',
 	marker => {size => 20},
 	name => 'III',
 );
 $anscombe_plot->add_trace($third_anscombe);
 my $fourth_anscombe = Chart::Plotly::Trace::Scatter->new( 
 	x => $anscombe_quartet->{'x4'},
 	y => $anscombe_quartet->{'y4'},
 	xaxis => 'x4',
 	yaxis => 'y4',
 	mode => 'markers',
 	marker => {size => 20},
 	name => 'IV'
 );
 $anscombe_plot->add_trace($fourth_anscombe);
 
 show_plot($anscombe_plot)

=head1 METHODS

=head2 get

Returns the classic Anscombe dataset as a reference.

By default returns a hash ref with the column names as the keys and data as the values as an array ref.
You can get the data in the format you want using the argument as and indicating a valid class in the 
namespace Data::Dataset::Classic::Adapter::*

=head1 SEE ALSO

L<Wikipedia: Anscombe's quartet|https://en.wikipedia.org/wiki/Anscombe's_quartet>

1;

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
