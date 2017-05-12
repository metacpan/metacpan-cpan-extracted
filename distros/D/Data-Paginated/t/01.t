use strict;

use Test::More tests => 2;
use Data::Paginated;

{
	my $pag = Data::Paginated->new({
			entries          => [ 1 .. 20 ],
			entries_per_page => 5,
		});
	my @data = $pag->page_data;
	is_deeply \@data, [ 1 .. 5 ], "First page";
}

{
	my $pag = Data::Paginated->new({
			entries          => [ 1 .. 20 ],
			entries_per_page => 5,
			current_page     => 2,
		});
	my @data = $pag->page_data;
	is_deeply \@data, [ 6 .. 10 ], "Second page";
}

