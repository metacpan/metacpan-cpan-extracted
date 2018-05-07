use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Splom;

use Data::Dataset::Classic::Iris;

my $convert_array_to_arrayref = sub {[@_]};
my $iris = Data::Dataset::Classic::Iris::get(as => 'Data::Table');
my $data = $iris->group(['species'],[$iris->header], [$convert_array_to_arrayref, $convert_array_to_arrayref, $convert_array_to_arrayref, $convert_array_to_arrayref, $convert_array_to_arrayref], [map { join "", map {ucfirst} split /_/, $_ } $iris->header], 0 );

my @data_to_plot;
my $iterator = $data->iterator();
while (my $row = $iterator->()) {
    my $dimensions = [
        map { { label => $_, values => $row->{$_} } } qw(SepalLength SepalWidth PetalLength PetalWidth)
    ];
    push @data_to_plot, Chart::Plotly::Trace::Splom->new(
        name => $row->{species},
        dimensions => $dimensions
    );
}

show_plot([@data_to_plot]);

