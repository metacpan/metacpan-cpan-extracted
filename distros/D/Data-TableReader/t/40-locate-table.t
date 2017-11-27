#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

# Find fields in the exact order they are present in the file
subtest basic => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => { CLASS => 'Mock', data => mock_data() },
			fields => [
				{ name => 'name' },
				{ name => 'address' },
				{ name => 'city' },
				{ name => 'state' },
				{ name => 'zip' },
			],
			log => $log,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' );
	is_deeply( $ex->col_map, $ex->fields, 'col map' );
	is_deeply( $ex->field_map, { name => 0, address => 1, city => 2, state => 3, zip => 4 }, 'field map' );
	ok( my $i= $ex->iterator, 'iterator' );
	is_deeply( $i->(), { name => 'Someone', address => '123 Long St', city => 'Somewhere', state => 'OH', zip => '45678' }, 'first row' );
	is_deeply( $i->(), { name => 'Another', address => '01 Main St', city => 'Elsewhere', state => 'OH', zip => '45678' }, 'third row' );
	is( $i->(), undef, 'eof' );
};

subtest find_on_second_sheet => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => { CLASS => 'Mock', data => mock_data() },
			fields => [
				{ name => 'postcode' },
				{ name => 'country' },
				{ name => 'state' },
			],
			log => $log,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' );
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
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						[qw( q w e r t y )],
						[qw( q w e r t a s d )],
					]
				],
			},
			fields => [
				{ name => 'q', required => 1 },
				{ name => 'w', required => 1 },
				{ name => 'a', required => 0 },
				{ name => 'b', required => 0 },
				{ name => 'y', required => 0 },
				{ name => 's', required => 1 },
			],
			log => $log,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' );
	is_deeply( $ex->field_map, { q => 0, w => 1, a => 5, s => 6 }, 'field_map' );
	is_deeply( $ex->iterator->all(), [], 'immediate eof' );
};

subtest multiline_header => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						[qw( a b c )],
						[qw( d e f )],
						[qw( g b c )],
						[qw( A B C )],
					]
				]
			},
			fields => [
				{ name => 'a', header => "d g" },
				{ name => 'b', header => 'b' },
				{ name => 'c', header => qr/^f\nc$/ },
			],
			log => $log,
		], 'TableReader' );
	is( $ex->header_row_combine, 2, 'header_row_combine' );
	ok( $ex->find_table, 'found table' );
	is_deeply( $ex->field_map, { a => 0, b => 1, c => 2 }, 'field_map' );
	is_deeply( $ex->iterator->all(), [{a=>'A',b=>'B',c=>'C'}], 'found row' );
};

subtest multi_column => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						[qw( a b a c a d )],
						[qw( 1 2 3 4 5 6 )],
					]
				]
			},
			fields => [
				{ name => 'a', header => qr/a|c/, array => 1 },
				{ name => 'd' },
			],
			log => $log,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' );
	is_deeply( $ex->field_map, { a => [0,2,3,4], d => 5 }, 'field_map' );
	is_deeply( $ex->iterator->all(), [{a => [1,3,4,5], d => 6}], 'rows' );
};

subtest array_at_end => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						[qw( a b c ),'','','','',''],
						[qw( 1 2 3 4 5 6 7 8 9 )],
						[qw( 1 2 3 4 5 6 7 8 9 10 11 12 13 )],
						[qw( 1 2 3 4 )],
					]
				]
			},
			fields => [
				'a',
				{ name => 'c', array => 1 },
				{ name => 'c', array => 1, header => '', follows => 'c' },
			],
			log => $log,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' );
	is_deeply( $ex->field_map, { a => 0, c => [2,3,4,5,6,7] }, 'field_map' );
	my $i= $ex->iterator;
	is_deeply( $i->(), { a => 1, c => [3,4,5,6,7,8] }, 'row1' );
	is_deeply( $i->(), { a => 1, c => [3,4,5,6,7,8] }, 'row1' );
	is_deeply( $i->(), { a => 1, c => [3,4,undef,undef,undef,undef] }, 'row1' );
	is( $i->(), undef, 'eof' );
};

subtest complex_follows => sub {
	my $ex= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						['name', 'start coords','','','','end coords','','','',''],
						['',     'x', 'y', 'w', 'h',     'x','y','w','h'],
						['foo',  '1', '1', '6', '6',     '2','2','8','8'],
					]
				]
			},
			fields => [
				'name',
				{ name => 'start_x', header => qr/start.*\nx/ },
				{ name => 'start_y', header => 'y', follows => 'start_x' },
				{ name => 'end_x', header => qr/end.*\nx/ },
				{ name => 'end_y', header => 'y', follows => 'end_x' }
			],
			log => $log,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' );
	is_deeply( $ex->field_map, { name => 0, start_x => 1, start_y => 2, end_x => 5, end_y => 6 }, 'field_map' );
	my $i= $ex->iterator;
	is_deeply( $i->(), { name => 'foo', start_x => 1, start_y => 1, end_x => 2, end_y => 2 }, 'row1' );
	is( $i->(), undef, 'eof' );
};

done_testing;

sub mock_data {
	[
		[ map { [ split /\t/, $_, 5 ] } split "\n", <<'END'
Name	Address	City	State	Zip
Someone	123 Long St	Somewhere	OH	45678
				
Another	01 Main St	Elsewhere	OH	45678
END
		],
		[ map { [ split /\t/, $_, 11 ] } split "\n", <<'END'
Zip Codes				Cities				State Postal Codes		
Zip	Lat	Lon		with population > 1,000,000				State	PostCode	Country
45001	39.138752	-84.709618		City	State	Population		Alberta	AB	CA
45002	39.182833	-84.723477		New York City	New York	8,550,405		Alaska	AK	US
45003	39.588296	-84.786326		Los Angeles	California	3,971,883		Alabama	AL	US
				Chicago	Illinois	2,720,546		Arkansas	AR	US
				Houston	Texas	2,296,224		American Samoa	AS	US
END
		]
	]
}