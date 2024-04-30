#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Log::Any '$log';
use Log::Any::Adapter 'TAP';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

subtest trim_options => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( trim retrim codetrim notrim )],
					[ ' abc ', ' abc ', ' abc ', ' abc ' ],
				],
			],
			fields => [
				{ name => 'notrim',   trim => 0 },
				{ name => 'trim',     trim => 1 },
				{ name => 'retrim',   trim => qr/a/ },
				{ name => 'codetrim', trim => sub { s/b//ig } },
			],
			log => $log
		], 'TableReader' );
	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";
	ok( my $i= $re->iterator, 'create iterator' );
	is( $i->dataset_idx, 0, 'dataset_idx=0' );
	is( $i->row, 1, 'row=1' );
	is_deeply( $i->all, [ { trim => 'abc', retrim => ' bc ', codetrim => ' ac ', notrim => ' abc ' } ], 'values' );
	is( $i->row, 2, 'row=2' );
};

subtest multiple_iterator => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( a b c )],
					[qw( 1 2 3 )],
				]
			],
			fields => ['a','b','c'],
			log => $log
		], 'TableReader' );
	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";
	ok( my $i= $re->iterator, 'create iterator' );
	Scalar::Util::weaken( my $wref= $i );
	undef $i;
	is( $wref, undef, 'first iterator garbage collected' );
	ok( my $i2= $re->iterator, 'second interator' );
	ok( my $i3= $re->iterator, 'third iterator' );
	is( $i2->row, 1, 'i2 row=1' );
	is( $i3->row, 1, 'i3 row=1' );
	is_deeply( $i2->all, [ { a => 1, b => 2, c => 3 } ], 'read rows from i2' );
	is( $i3->row, 1, 'i3 row=1' );
	is_deeply( $i3->all, [ { a => 1, b => 2, c => 3 } ], 'read rows from i3' );
};

subtest record_class_array => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( c b a b )],
					[qw( 1 2 3 4 )],
					[qw( 5 6 7 ),''],
				]
			],
			fields => [
				'a',
				{ name => 'b', array => 1 },
				'c',
				{ name => 'd', required => 0 },
			],
			record_class => 'ARRAY',
			log => \my @messages,
		], 'TableReader' );
	ok( $re->find_table, 'find_table' ) or note explain \@messages;
	ok( my $i= $re->iterator, 'create iterator' );
	is_deeply( $i->(), [ 3, [2,4], 1, undef ], 'row 1' );
	is_deeply( $i->(), [ 7, [6, undef], 5, undef ], 'row 2' );
	is( $i->(), undef, 'eof' );
};

done_testing;
