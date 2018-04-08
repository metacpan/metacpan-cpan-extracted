use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Table;
# Example data from: https://plot.ly/javascript/table/#basic-table
my $table = Chart::Plotly::Trace::Table->new(

    header => {
        values => [ [ "EXPENSES" ], [ "Q1" ],
            [ "Q2" ], [ "Q3" ], [ "Q4" ] ],
        align  => "center",
        line   => { width => 1, color => 'black' },
        fill   => { color => "grey" },
        font   => { family => "Arial", size => 12, color => "white" }
    },
    cells  => {
        values => [
            [ 'Salaries', 'Office', 'Merchandise', 'Legal', 'TOTAL' ],
            [ 1200000, 20000, 80000, 2000, 12120000 ],
            [ 1300000, 20000, 70000, 2000, 130902000 ],
            [ 1300000, 20000, 120000, 2000, 131222000 ],
            [ 1400000, 20000, 90000, 2000, 14102000 ] ],
        align  => "center",
        line   => { color => "black", width => 1 },
        font   => { family => "Arial", size => 11, color => [ "black" ] }
    }
);

show_plot([ $table ]);

