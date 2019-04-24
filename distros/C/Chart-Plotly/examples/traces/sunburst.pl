use Chart::Plotly;
use Chart::Plotly::Trace::Sunburst;
use Chart::Plotly::Plot;

# Example from https://github.com/plotly/plotly.js/blob/50922a6511b597dc20a68aba1594b2cf84a9c57d/test/image/mocks/sunburst_first.json

my $trace1 = Chart::Plotly::Trace::Sunburst->new(
      "labels"=>["Eve", "Cain", "Seth", "Enos", "Noam", "Abel", "Awan", "Enoch", "Azura"],
      "parents"=>["", "Eve", "Eve", "Seth", "Seth", "Eve", "Eve", "Awan", "Eve" ],
      "domain"=>{"x"=>[0, 0.5]}
  );

my $trace2 = Chart::Plotly::Trace::Sunburst->new(
      "labels"=>["Cain", "Seth", "Enos", "Noam", "Abel", "Awan", "Enoch", "Azura"],
      "parents"=>["Eve", "Eve", "Seth", "Seth", "Eve", "Eve", "Awan", "Eve" ],
      "domain"=>{"x"=>[0.5, 1]}
  );

my $plot = Chart::Plotly::Plot->new(
    traces => [ $trace1, $trace2 ],
);

Chart::Plotly::show_plot($plot);
