#!perl

use strict;
use warnings;
use Test::More;
use JSON::XS;
use Data::Google::Visualization::DataTable;
use Data::Google::Visualization::DataSource;

# Create a simple datatable for testing
my $datatable = Data::Google::Visualization::DataTable->new();
$datatable->add_columns(
    { id => 'person', label => "Person", type => 'string', },
);
$datatable->add_rows(
	{ person => "Steve Jobs" },
	{ person => "Lou Reed"   },
);

# Check various inputs do something sane
for my $test (
	{
		name => "All the defaults",
		input => {
			datatable => $datatable,
			reqId => 5,
		},
		expected => {
			reqId => 5,
			status => 'ok',
		}
	}
) {
	my $datasource = Data::Google::Visualization::DataSource->new(
		{ %{$test->{'input'}}, datasource_auth => 'boom' }
	);
	my ( $header, $payload ) = $datasource->serialize;
	$payload = decode_json( $payload );
	for my $key ( keys %{$test->{'expected'}} ) {
		is( $payload->{$key}, $test->{'expected'}->{$key},
			"$key matches" );
	}
}

done_testing();