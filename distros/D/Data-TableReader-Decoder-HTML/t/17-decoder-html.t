#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Test::More;
use Try::Tiny;
use File::Spec::Functions 'catfile';
use Log::Any '$log';
use Log::Any::Adapter 'TAP';
use Data::TableReader::Decoder::HTML;
use Data::TableReader 0.008;
my $log_fn= sub { $log->can($_[0])->($log, $_[1]) };

my $fname= catfile( $FindBin::Bin, 'data', 'Data.html' );
my @expected_data= (
	[ # Table 1
		[ qw( Name   Address        City         State  Zip  ) ],
		[ 'Someone','123 Long St', 'Somewhere', 'OH', 45678 ],
		[ 'Another','01 Main St',  'Elsewhere', 'OH', 45678 ],
	],
	[ # Table 2
		[ qw( Name   Address        City         State  ) ],
		[ 'Someone','123 Long St', 'Somewhere', 'OH' ],
		[ 'Another','01 Main St',  'Elsewhere', 'OH' ],
	]
);

subtest simple_iteration => \&test_simple_iteration;
sub test_simple_iteration {
	open my $fh, '<:raw', $fname or die "open: $!";
	my $dec= new_ok( 'Data::TableReader::Decoder::HTML',
		[ file_name => $fname, file_handle => $fh, _log => $log_fn ],
		'new HTML decoder'
	);
	ok( $dec->parse, 'able to parse HTML' );
	ok( my $iter= $dec->iterator, 'got iterator' );
	for (@{ $expected_data[0] }) {
		is_deeply( $iter->(), $_, $iter->position );
	}
	
	done_testing;
}

subtest seek_tell => \&test_seek_tell;
sub test_seek_tell {
	open my $fh, '<:raw', $fname or die "open: $!";
	my $dec= new_ok( 'Data::TableReader::Decoder::HTML',
		[ file_name => $fname, file_handle => $fh, _log => $log_fn ],
		'new HTML decoder'
	);
	ok( $dec->parse, 'able to parse HTML' );
	ok( my $iter= $dec->iterator, 'got iterator' );
	my $pos= $iter->tell;
	is( $iter->row, 0, 'row=0' );
	is( $iter->progress, 0, 'progress=0' );
	is_deeply( $iter->(), $expected_data[0][0], 'correct first row' );
	is( $iter->row, 1, 'row=1' );
	$iter->seek($pos);
	is( $iter->row, 0, 'row=0' );
	is( $iter->progress, 0, 'progress=0 again' );
	is_deeply( $iter->(), $expected_data[0][0], 'correct first row' );
	
	done_testing;
}

subtest multiple_tables => \&test_multiple_tables;
sub test_multiple_tables {
	open my $fh, '<:raw', $fname or die "open: $!";
	my $dec= new_ok( 'Data::TableReader::Decoder::HTML',
		[ file_name => $fname, file_handle => $fh, _log => $log_fn ],
		'new HTML decoder'
	);
	my $iter= $dec->iterator;
	is_deeply( $iter->(), $expected_data[0][0], 'correct first row' );
	my $pos= $iter->tell;
	ok( $iter->next_dataset, 'next_dataset' );
	for (@{ $expected_data[1] }) {
		is_deeply( $iter->(), $_, $iter->position );
	}
	$iter->seek($pos);
	is_deeply( $iter->(), $expected_data[0][1], 'correct second row' );
	
	done_testing;
}

done_testing;