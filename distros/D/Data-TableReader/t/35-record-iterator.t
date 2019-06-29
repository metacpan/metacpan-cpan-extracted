#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Log::Any '$log';
use Log::Any::Adapter 'TAP';

use_ok( 'Data::TableReader' ) or BAIL_OUT;

subtest trim_options => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						[qw( trim retrim codetrim notrim )],
						[ ' abc ', ' abc ', ' abc ', ' abc ' ],
					],
				]
			},
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
	is_deeply( $i->all, [ { trim => 'abc', retrim => ' bc ', codetrim => ' ac ', notrim => ' abc ' } ], 'values' );
};

subtest multiple_iterator => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => \'',
			decoder => {
				CLASS => 'Mock',
				data => [
					[
						[qw( a b c )],
						[qw( 1 2 3 )],
					]
				]
			},
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
	is_deeply( $i2->all, [ { a => 1, b => 2, c => 3 } ], 'read rows from i2' );
	is_deeply( $i3->all, [ { a => 1, b => 2, c => 3 } ], 'read rows from i3' );
};

done_testing;
