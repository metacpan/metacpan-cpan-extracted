#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP', filter => 'warn';
use Scalar::Util 'refaddr';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

# Find fields in the exact order they are present in the file
sub mock_data {
	[
		[
			[ qw( Name Address City State Zip ) ],
			[ 'Someone', '123 Long St', 'Somewhere', 'OH', '45678' ],
			[ ('')x5 ],
			[ 'Another', '01 Main St',  'Elsewhere', 'OH', '45678' ],
		],
		[
			[ 'Zip Codes','',   '',                '','Cities',                     '','','',       'State Postal Codes','','' ],
			[ 'Zip',   'Lat','Lon',                '','with population > 1,000,000','','','',       'State','PostCode','Country'],
			[ '45001', '39.138752','-84.709618',   '','City',         'State',     'Population','', 'Alberta','AB','CA'],
			[ '45002', '39.182833','-84.723477',   '','New York City','New York',  '8,550,405','',  'Alaska','AK','US' ],
			[ '45003', '39.588296','-84.786326',   '','Los Angeles',  'California','3,971,883','',  'Alabama','AL','US' ],
			[ '','','',                            '','Chicago',      'Illinois',  '2,720,546','',  'Arkansas','AR','US' ],
			[ '','','',                            '','Houston',      'Texas',     '2,296,224','',  'American Samoa','AS','US' ],
		]
	]
}
subtest basic => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => mock_data(),
			fields => [
				{ name => 'name' },
				{ name => 'address' },
				{ name => 'city' },
				{ name => 'state' },
				{ name => 'zip' },
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->col_map, $ex->fields, 'col map' );
	is_deeply( $ex->field_map, { name => 0, address => 1, city => 2, state => 3, zip => 4 }, 'field map' );
	is( $ex->table_search_results->{found}, $ex->table_search_results->{candidates}[0], 'search results' );
	is( $ex->table_search_results->{found}{row_idx}, 0, 'found row_idx' );
	is( $ex->table_search_results->{found}{dataset_idx}, 0, 'found dataset_idx' );
	ok( my $i= $ex->iterator, 'iterator' );
	is_deeply( $i->(), { name => 'Someone', address => '123 Long St', city => 'Somewhere', state => 'OH', zip => '45678' }, 'first row' );
	is_deeply( $i->(), { name => 'Another', address => '01 Main St', city => 'Elsewhere', state => 'OH', zip => '45678' }, 'third row' );
	is( $i->(), undef, 'eof' );
};

subtest find_on_second_sheet => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => mock_data(),
			fields => [
				{ name => 'postcode' },
				{ name => 'country' },
				{ name => 'state' },
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	ok( my $i= $ex->iterator, 'iterator' );
	is_deeply( $i->(), { state => 'Alberta', postcode => 'AB', country => 'CA' }, 'row 1' );
	is_deeply( $i->(), { state => 'Alaska',  postcode => 'AK', country => 'US' }, 'row 2' );
	is_deeply( $i->(), { state => 'Alabama', postcode => 'AL', country => 'US' }, 'row 3' );
	is_deeply( $i->(), { state => 'Arkansas',postcode => 'AR', country => 'US' }, 'row 4' );
	is_deeply( $i->(), { state => 'American Samoa', postcode => 'AS', country => 'US' }, 'row 5' );
	is( $i->(), undef, 'eof' );
};

subtest find_required => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( q w e r t y )],
				[qw( q w e r t a s d )],
			],
			fields => [
				{ name => 'q', required => 1 },
				{ name => 'w', required => 1 },
				{ name => 'a', required => 0 },
				{ name => 'b', required => 0 },
				{ name => 'y', required => 0 },
				{ name => 's', required => 1 },
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { q => 0, w => 1, a => 5, s => 6 }, 'field_map' );
	is_deeply( $ex->iterator->all(), [], 'immediate eof' );
};

subtest multiline_header => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b c )],
				[qw( d e f )],
				[qw( g b c )],
				[qw( A B C )],
			],
			fields => [
				{ name => 'a', header => "d g" },
				{ name => 'b', header => "b\ne\nb" },
				{ name => 'c', header => qr/f\nc$/ },
			],
			log => \my @messages,
		], 'TableReader' );
	is( $ex->header_row_combine, 3, 'header_row_combine' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { a => 0, b => 1, c => 2 }, 'field_map' );
	is_deeply( $ex->iterator->all(), [{a=>'A',b=>'B',c=>'C'}], 'found row' );
};

subtest multi_column => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b a c a d )],
				[qw( 1 2 3 4 5 6 )],
			],
			fields => [
				{ name => 'a', header => qr/a|c/, array => 1 },
				{ name => 'd' },
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { a => [0,2,3,4], d => 5 }, 'field_map' );
	is_deeply( $ex->iterator->all(), [{a => [1,3,4,5], d => 6}], 'rows' );
};

subtest array_at_end => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b c ),'','','','',''],
				[qw( 1 2 3 4 5 6 7 8 9 )],
				[qw( 1 2 3 4 5 6 7 8 9 10 11 12 13 )],
				[qw( 1 2 3 4 )],
			],
			fields => [
				'a',
				{ name => 'c', array => 1 },
				{ name => 'c', array => 1, header => '', follows => 'c' },
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { a => 0, c => [2,3,4,5,6,7] }, 'field_map' );
	my $i= $ex->iterator;
	is_deeply( $i->(), { a => 1, c => [3,4,5,6,7,8] }, 'row1' );
	is_deeply( $i->(), { a => 1, c => [3,4,5,6,7,8] }, 'row1' );
	is_deeply( $i->(), { a => 1, c => [3,4,undef,undef,undef,undef] }, 'row1' );
	is( $i->(), undef, 'eof' );
};

subtest multiple_arrays => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b b b c d d d e )],
				[qw( 1 2 3 4 5 6 7 8 9 )],
			],
			fields => [
				'a',
				{ name => 'b', array => 1 },
				'c',
				{ name => 'd', array => 1 },
				'e',
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { a => 0, b => [1,2,3], c => 4, d => [5,6,7], e => 8 }, 'field_map' );
	my $i= $ex->iterator;
	is_deeply( $i->(), { a => 1, b => [2,3,4], c => 5, d => [6,7,8], e => 9 }, 'row1' );
	is( $i->(), undef, 'eof' );
};

subtest discontinuous_array => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b b b c b b e )],
				[qw( 1 2 3 4 5 6 7 8 )],
			],
			fields => [
				'a',
				{ name => 'b', array => 1 },
				'c',
				'e',
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { a => 0, b => [1,2,3,5,6], c => 4, e => 7 }, 'field_map' );
	my $i= $ex->iterator;
	is_deeply( $i->(), { a => 1, b => [2,3,4,6,7], c => 5, e => 8 }, 'row1' );
	is( $i->(), undef, 'eof' );
};

subtest complex_follows => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				['name', 'start coords','','','','end coords','','','',''],
				['',     'x', 'y', 'w', 'h',     'x','y','w','h'],
				['foo',  '1', '1', '6', '6',     '2','2','8','8'],
			],
			fields => [
				'name',
				{ name => 'start_x', header => qr/start.*\nx/ },
				{ name => 'start_y', header => 'y', follows => 'start_x' },
				{ name => 'end_x', header => qr/end.*\nx/ },
				{ name => 'end_y', header => 'y', follows => 'end_x' }
			],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or diag explain \@messages;
	is_deeply( $ex->field_map, { name => 0, start_x => 1, start_y => 2, end_x => 5, end_y => 6 }, 'field_map' );
	my $i= $ex->iterator;
	is_deeply( $i->(), { name => 'foo', start_x => 1, start_y => 1, end_x => 2, end_y => 2 }, 'row1' );
	is( $i->(), undef, 'eof' );
};

subtest col_map_lazy_search => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b c )],
			],
			fields => [qw( a b c )],
			log => \my @messages,
		], 'TableReader' );

	ok( !$ex->has_table_search_results, 'search has not run yet' );
	ok( !$ex->has_col_map, 'no col_map yet' );

	is_deeply(
		$ex->col_map,
		$ex->fields,
		'reading col_map lazily detects the table',
	);

	ok( $ex->has_table_search_results, 'lazy read populated search results' );
	ok( $ex->has_col_map, 'derived col_map now exists' );
};

subtest supplied_col_map_survives_search_clear => sub {
	my $base_map= [ undef, 'b', undef ];

	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b c )],
			],
			fields => [qw( a b c )],
			col_map => $base_map,
			log => \my @messages,
		], 'TableReader' );

	ok( $ex->find_table, 'found table' ) or diag explain \@messages;

	is_deeply(
		[ map defined()? $_->name : undef, @{$ex->col_map} ],
		[qw( a b c )],
		'effective col_map includes detected fields',
	);

	$ex->clear_table_search_results;

	is_deeply(
		[ map defined()? $_->name : undef, @{$ex->col_map} ],
		[ undef, 'b', undef ],
		'clearing search results restores supplied col_map',
	);

	ok(
		!$ex->has_table_search_results,
		'reading a supplied col_map does not rerun table search',
	);
};

subtest col_map_setter_does_not_modify_caller => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b )],
			],
			fields => [qw( a b )],
			log => \my @messages,
		], 'TableReader' );

	my $map= [ 'a', undef ];

	$ex->col_map($map);

	is_deeply(
		$map,
		[ 'a', undef ],
		'col_map setter does not modify caller array',
	);

	ok(
		ref($ex->col_map->[0]),
		'stored col_map resolves names to Field objects',
	);

	$map->[1]= 'changed';

	is(
		$ex->col_map->[1],
		undef,
		'modifying caller array does not modify stored col_map',
	);
};

subtest col_map_re_resolves_after_fields_change => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a )],
			],
			fields => [qw( a )],
			col_map => [ 'a' ],
			log => \my @messages,
		], 'TableReader' );

	my $old_field= $ex->col_map->[0];

	$ex->fields([ 'a' ]);

	my $new_field= $ex->col_map->[0];

	is(
		$new_field,
		$ex->fields->[0],
		'col_map resolves to the replacement Field object',
	);

	isnt(
		refaddr($new_field),
		refaddr($old_field),
		'col_map does not retain stale Field object',
	);
};

subtest repeated_find_uses_supplied_col_map => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b )],
			],
			fields => [qw( a b )],
			static_field_order => 1,
			log => \my @messages,
		], 'TableReader' );

	ok( $ex->find_table, 'initial search succeeds' )
		or diag explain \@messages;

	is_deeply(
		[ map $_->name, @{$ex->col_map} ],
		[qw( a b )],
		'initial derived map',
	);

	$ex->col_map([qw( b a )]);
	@messages= ();

	ok(
		!$ex->find_table,
		'second search uses newly supplied map, not previous result',
	);

	like(
		join("\n", map $_->[1], @messages),
		qr/Header at column 1 does not look like field b/,
		'failure describes supplied map mismatch',
	);
};

subtest headerless_requires_static_order => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( 1 2 )],
			],
			fields => [qw( a b )],
			header_row_at => undef,
			static_field_order => 0,
			log => \my @messages,
		], 'TableReader' );

	my ($result, $exception);
	{
		local $@;
		eval {
			$result= $ex->find_table;
			1;
		} or $exception= $@;
	}

	is( $exception, undef, 'find_table does not die' );
	ok( !$result, 'find_table reports failure' );

	is(
		$ex->table_search_results->{fatal},
		"You must enable 'static_field_order' if there is no header row",
		'failure reason is retained in search results',
	);
};

subtest headerless_with_static_order => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( 1 2 )],
			],
			fields => [qw( a b )],
			header_row_at => undef,
			static_field_order => 1,
			log => \my @messages,
		], 'TableReader' );

	ok( $ex->find_table, 'headerless table accepted in static mode' )
		or diag explain \@messages;

	is_deeply(
		[ map $_->name, @{$ex->col_map} ],
		[qw( a b )],
		'fields become the headerless col_map',
	);

	is(
		$ex->table_search_results->{found}{row_idx},
		-1,
		'headerless result uses row_idx -1',
	);

	is(
		$ex->table_search_results->{found}{row},
		undef,
		'headerless result has no header row number',
	);
};

subtest static_header_error_uses_one_based_column => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a wrong )],
			],
			fields => [qw( a b )],
			static_field_order => 1,
			log => \my @messages,
		], 'TableReader' );

	ok( !$ex->find_table, 'header mismatch fails search' );

	my $candidate= $ex->table_search_results->{candidates}[0];

	like(
		join("\n", map $_->[1], @{$candidate->{messages}}),
		qr/Header at column 2 does not look like field b/,
		'static mismatch reports a one-based column number',
	);
};

subtest undefined_header_cells => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[ undef, 'a' ],
			],
			fields => [ 'a' ],
			on_unknown_columns => 'warn',
			log => \my @messages,
		], 'TableReader' );

	my ($result, $exception);
	{
		local $@;
		eval {
			$result= $ex->find_table;
			1;
		} or $exception= $@;
	}

	is( $exception, undef, 'undefined header cell does not die' );
	ok( $result, 'table is still detected' );

	is_deeply(
		$ex->field_map,
		{ a => 1 },
		'defined header is mapped normally',
	);

	like(
		join("\n", map $_->[1], @messages),
		qr/Ignoring unknown columns: <undef>/,
		'undefined header is formatted safely',
	);
};

subtest on_partial_match_callback_arguments => sub {
	my @callback_args;

	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[ 'a', 'not-b' ],
				[ 'a', 'b' ],
			],
			fields => [
				{ name => 'a', required => 1 },
				{ name => 'b', required => 1 },
			],
			on_partial_match => sub {
				@callback_args= @_;
				return 'next';
			},
			log => \my @messages,
		], 'TableReader' );

	ok( $ex->find_table, 'search continues after partial match' )
		or diag explain \@messages;

	is( $callback_args[0], $ex, 'callback receives reader' );

	is(
		ref($callback_args[1]),
		'HASH',
		'callback receives candidate hashref',
	);

	is(
		$callback_args[1]{row},
		1,
		'candidate describes partial row',
	);

	is_deeply(
		$callback_args[2],
		[ 'a', 'not-b' ],
		'callback receives header row arrayref',
	);

	is(
		$ex->table_search_results->{found}{row},
		2,
		'second row is selected',
	);
};

subtest on_unknown_columns_callback_arguments => sub {
	my @callback_args;

	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a extra )],
			],
			fields => [ 'a' ],
			on_unknown_columns => sub {
				@callback_args= @_;
				return 'warn';
			},
			log => \my @messages,
		], 'TableReader' );

	ok( $ex->find_table, 'callback permits unknown column' )
		or diag explain \@messages;

	is( $callback_args[0], $ex, 'callback receives reader' );

	is_deeply(
		$callback_args[1],
		[qw( a extra )],
		'callback receives headers arrayref',
	);

	is_deeply(
		$callback_args[2],
		[1],
		'callback receives unmatched indices arrayref',
	);

	is(
		ref($callback_args[3]),
		'HASH',
		'callback receives candidate hashref',
	);

	is(
		$callback_args[3]{row},
		1,
		'candidate contains row information',
	);
};

subtest empty_fields_fail_at_find_table => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => [
				[qw( a b )],
			],
			fields => [],
			log => \my @messages,
		], 'TableReader' );

	my ($result, $exception);
	{
		local $@;
		eval {
			$result= $ex->find_table;
			1;
		} or $exception= $@;
	}

	like( $exception, qr/No fields/, 'empty fields cause an exception' );
	ok( !$ex->has_table_search_results, 'empty fields do not identify a table' );

	is(
		$ex->header_row_combine,
		0,
		'empty fields produce zero header rows to combine',
	);
};

done_testing;
