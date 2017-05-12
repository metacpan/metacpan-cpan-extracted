use strict;
use warnings;
use Test::Most;

use lib "t/lib";
use TestData;

my $db = get_db();

my $data = {
	'%Temptation%' => [1, 0],
	'%Kawaii%' => [1, 0],
	'%City%' => [0, 0],
	'%Thresher%' => [0, 0],
	'%1756-0500-4-434.pdf%' => [0, 1],
	'%Patrick-Wyatt-Writing-reliable-online-game-services.pdf%' => [0, 1],
	'%journal.pone.0046362.pdf%' => [0, 1],
};

plan tests => ( scalar keys %$data );

for my $match (keys %$data) {
	my $item = $db
		->schema->resultset('Item')
		->search_by_field( {
			title => { like => $match }
		} )->first;
	my $item_data = $data->{$match};
	subtest "Testing @{[$item->fields->{title}]}" => sub {
		pass if not( $item->is_source_item ^ $item_data->[0] );
		pass if not( $item->is_attachment ^ $item_data->[1] );
	};
}




done_testing;
