#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP', filter => 'warn';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

# Find columns when the first is known to be the ID
subtest one_overridden_col => sub {
	my $ex= new_ok( 'Data::TableReader', [
			fields => [
				{ name => 'prod_num' },
				{ name => 'description' },
				{ name => 'weight' },
			],
			input => [
				[ 'Product', 'Description', 'Weight' ],
				[ 'ABC-DE-F', 'Precision cut widget', 1.25 ],
				[ 'ABC-DE-G', 'Widget with feature X', 4.5 ],
			],
			col_map => [ 'prod_num' ],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or note explain \@messages;
	is_deeply( $ex->col_map, $ex->fields, 'col map' );
	is_deeply( $ex->field_map, { prod_num => 0, description => 1, weight => 2 }, 'field map' );
	ok( my $i= $ex->iterator, 'iterator' );
	is_deeply( $i->(), { prod_num => 'ABC-DE-F', description => 'Precision cut widget', weight => 1.25 }, 'row2' );
	is_deeply( $i->(), { prod_num => 'ABC-DE-G', description => 'Widget with feature X', weight => 4.5 }, 'row3' );
	is( $i->(), undef, 'eof' );
};

# Specify all columns in the colmap
subtest all_overridden_col => sub {
	my $ex= new_ok( 'Data::TableReader', [
			fields => [
				{ name => 'prod_num' },
				{ name => 'a1' },
				{ name => 'a2' },
			],
			input => [
				[ 'Product', 'Description', 'Weight' ],
				[ 'ABC-DE-F', 'Precision cut widget', 1.25 ],
				[ 'ABC-DE-G', 'Widget with feature X', 4.5 ],
			],
			col_map => [ 'prod_num', 'a1', 'a2' ],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or note explain \@messages;
	is_deeply( $ex->col_map, $ex->fields, 'col map' );
	is_deeply( $ex->field_map, { prod_num => 0, a1 => 1, a2 => 2 }, 'field map' );
	ok( my $i= $ex->iterator, 'iterator' );
	is_deeply( $i->(), { prod_num => 'ABC-DE-F', a1 => 'Precision cut widget',  a2 => 1.25 }, 'row2' );
	is_deeply( $i->(), { prod_num => 'ABC-DE-G', a1 => 'Widget with feature X', a2 => 4.5 }, 'row3' );
	is( $i->(), undef, 'eof' );
};

# Specify some columns in the colmap, but the others don't match anything, and
# need to just decide to use the first row in the header_row_at list for lack
# of a better indication.
subtest only_match_overridden => sub {
	my $ex= new_ok( 'Data::TableReader', [
			fields => [
				{ name => 'prod_num' },
				{ name => 'a1' },
				{ name => 'a2', required => 0 },
			],
			input => [
				[ 'Description about the file' ],
				[ 'Product', 'Description', 'Weight' ],
				[ 'ABC-DE-F', 'Precision cut widget', 1.25 ],
				[ 'ABC-DE-G', 'Widget with feature X', 4.5 ],
			],
			header_row_at => 2,
			col_map => [ 'prod_num', undef, 'a1' ],
			log => \my @messages,
		], 'TableReader' );
	ok( $ex->find_table, 'found table' ) or note explain \@messages;
	is_deeply( $ex->col_map, [ $ex->fields->[0], undef, $ex->fields->[1] ], 'col map' );
	is_deeply( $ex->field_map, { prod_num => 0, a1 => 2 }, 'field map' );
	ok( my $i= $ex->iterator, 'iterator' );
	is_deeply( $i->(), { prod_num => 'ABC-DE-F', a1 => 1.25 }, 'row2' );
	is_deeply( $i->(), { prod_num => 'ABC-DE-G', a1 => 4.5 }, 'row3' );
	is( $i->(), undef, 'eof' );
};

done_testing;
