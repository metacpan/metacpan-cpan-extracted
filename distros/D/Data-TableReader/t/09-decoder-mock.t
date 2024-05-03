#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Log::Any '$log';
use Log::Any::Adapter 'TAP';
use Data::TableReader::Decoder::Mock;

my $log_fn= sub { $log->can($_[0])->($log, $_[1]) };

sub table1 { [ [ 'a', 'b', 'c' ], [ 1, 2, 3 ], [ 4, 5, 6 ] ] };
sub table2 { [ [ 'x', 'y', 'z' ], [ 9, 8, 7 ], [ 6, 5, 4 ] ] };

subtest one_table => sub {
	my $expected= table1;
	my $d= new_ok( 'Data::TableReader::Decoder::Mock',
		[ table => table1, _log => $log_fn, file_name => undef, file_handle => undef ],
		'new decoder' );

	ok( my $iter= $d->iterator, 'got iterator' );
	is( $iter->row, 0, 'row=0' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );

	is_deeply( $iter->(), $expected->[0], 'first row' );
	is( $iter->row, 1, 'row=1' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );

	is_deeply( $iter->(), $expected->[1], 'second row' );
	is( $iter->row, 2, 'row=2' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );

	is_deeply( $iter->(), $expected->[2], 'third row' );
	is( $iter->row, 3, 'row=3' );

	is_deeply( $iter->(), undef, 'no fourth row' );
	is( $iter->row, 3, 'row=3' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );

	ok( $iter->seek(0), 'rewind' );
	is( $iter->row, 0, 'row=0' );
	is_deeply( $iter->(), $expected->[0], 'first row again' );
	is( $iter->row, 1, 'row=1' );

	is_deeply( $iter->([2,1]), [ '3', '2' ], 'slice from second row' );
	ok( !$iter->next_dataset, 'no next dataset' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );
};

subtest empty_table => sub {
	my $datasets= [ [], [] ];
	my $d= new_ok( 'Data::TableReader::Decoder::Mock',
		[ datasets => $datasets, _log => $log_fn, file_name => undef, file_handle => undef ],
		'new decoder' );

	ok( my $iter= $d->iterator, 'iterator' );
	is( $iter->row, 0, 'row=0' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );
	is( $iter->(), undef, 'eof' );
	is( $iter->row, 0, 'row=0' );

	ok( $iter->next_dataset, 'next_dataset' );
	is( $iter->row, 0, 'row=0' );
	is( $iter->dataset_idx, 1, 'dataset_idx=1' );
	is( $iter->(), undef, 'eof' );
	is( $iter->row, 0, 'row=0' );

	ok( !$iter->next_dataset, 'no next_dataset' );

	is_deeply( $datasets, [ [], [] ], 'backing data unchanged' );
};

subtest no_datasets => sub {
	my $datasets= [];
	my $d= new_ok( 'Data::TableReader::Decoder::Mock',
		[ datasets => $datasets, _log => $log_fn, file_name => undef, file_handle => undef ],
		'new decoder' );

	ok( my $iter= $d->iterator, 'iterator' );
	is( $iter->row, 0, 'row=0' );
	is( $iter->dataset_idx, 0, 'dataset_idx=0' );
	is( $iter->(), undef, 'eof' );
	is( $iter->row, 0, 'row=0' );

	ok( !$iter->next_dataset, 'no next_dataset' );

	is_deeply( $datasets, [], 'backing data unchanged' );
};

done_testing;
