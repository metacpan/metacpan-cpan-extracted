use Data::Table;
use HTML::Show;
use Chart::Plotly;

my $table = Data::Table::fromFile('morley.csv');

HTML::Show::show(
	Chart::Plotly::render_full_html(
		data => $table, 
	)); # Automatic dispatch
