
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

