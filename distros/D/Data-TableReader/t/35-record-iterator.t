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
				Data::TableReader::Field->new(name => 'b', array => 1),
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

subtest iterator_all_keeps_false_objects => sub {
	{
		package Local::FalseRecord;
		use overload
			'bool' => sub { 0 },
			fallback => 1;

		sub new {
			my ($class, $data)= @_;
			return bless $data, $class;
		}
	}

	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( a )],
					[1],
					[2],
				]
			],
			fields => ['a'],
			record_class => 'Local::FalseRecord',
			log => $log,
		], 'TableReader' );

	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";

	my $records= $re->iterator->all;

	is( scalar @$records, 2, 'all returns false-overloaded records' );
	isa_ok( $records->[0], 'Local::FalseRecord' );
	isa_ok( $records->[1], 'Local::FalseRecord' );
	is( $records->[0]{a}, 1, 'first record value' );
	is( $records->[1]{a}, 2, 'second record value' );
};

subtest iterator_tell_seek => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( a b )],
					[qw( 1 2 )],
					[qw( 3 4 )],
					[qw( 5 6 )],
				]
			],
			fields => [qw( a b )],
			log => $log,
		], 'TableReader' );

	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";
	ok( my $i= $re->iterator, 'create iterator' );

	is_deeply( $i->(), { a => 1, b => 2 }, 'read first row' );

	my $state= $i->tell;
	is( ref $state, 'ARRAY', 'tell returns arrayref' );
	is( scalar @$state, 4, 'tell returns complete iterator state' );

	is_deeply( $i->(), { a => 3, b => 4 }, 'read second row' );

	is( $i->seek($state), $i, 'seek returns iterator' );
	is_deeply(
		$i->(),
		{ a => 3, b => 4 },
		'seek restores position before second row',
	);

	is_deeply( $i->(), { a => 5, b => 6 }, 'continues after restored row' );
	is( $i->(), undef, 'eof' );
};

subtest iterator_seek_after_eof => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( a )],
					[1],
					[2],
				]
			],
			fields => ['a'],
			log => $log,
		], 'TableReader' );

	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";
	ok( my $i= $re->iterator, 'create iterator' );

	my $start= $i->tell;

	is_deeply( $i->(), { a => 1 }, 'first row' );
	is_deeply( $i->(), { a => 2 }, 'second row' );
	is( $i->(), undef, 'reached eof' );
	is( $i->(), undef, 'eof remains stable' );

	$i->seek($start);

	is_deeply(
		$i->(),
		{ a => 1 },
		'seek after eof resets closure eof state',
	);

	is_deeply( $i->(), { a => 2 }, 'second row after rewind' );
	is( $i->(), undef, 'eof after rewind' );
};

subtest iterator_seek_preserves_blank_row_state => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( a )],
					[1],
					[''],
					[''],
					[2],
				]
			],
			fields => ['a'],
			on_blank_row => 'next',
			log => \my @messages,
		], 'TableReader' );

	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";
	ok( my $i= $re->iterator, 'create iterator' );

	is_deeply( $i->(), { a => 1 }, 'first row' );

	my $before_blanks= $i->tell;

	is_deeply( $i->(), { a => 2 }, 'blank rows skipped before second row' );

	like(
		join("\n", map $_->[1], @messages),
		qr/Skipping blank rows from 3 until 4/,
		'blank row warning emitted',
	);

	@messages= ();
	$i->seek($before_blanks);

	is_deeply(
		$i->(),
		{ a => 2 },
		'seek restores blank-row tracking state',
	);

	like(
		join("\n", map $_->[1], @messages),
		qr/Skipping blank rows from 3 until 4/,
		'blank row warning is correct after seek',
	);
};

subtest iterator_seek_rejects_invalid_state => sub {
	my $re= new_ok( 'Data::TableReader', [
			input => [
				[
					[qw( a )],
					[1],
				]
			],
			fields => ['a'],
			log => $log,
		], 'TableReader' );

	ok( $re->find_table, 'find_table' ) or die "Can't continue without table";
	my $i= $re->iterator;

	for my $bad_state (
		undef,
		'not an arrayref',
		[],
		[1],
		[1, 2, 3],
		[1, 2, 3, 4, 5],
	) {
		my $ok= eval {
			$i->seek($bad_state);
			1;
		};

		ok( !$ok, 'invalid seek state rejected' );
		like(
			$@,
			qr/Expected arrayref of 4 elements/,
			'useful invalid-state error',
		);
	}
};

done_testing;
