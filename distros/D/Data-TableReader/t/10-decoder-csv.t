#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Log::Any '$log';
use Log::Any::Adapter 'TAP';
use Data::TableReader::Decoder::CSV;

my $csvmod;
plan skip_all => 'Need a CSV parser for this test'
	unless try { $csvmod= Data::TableReader::Decoder::CSV->default_csv_module };
note "CSV decoder is ".$csvmod." version ".$csvmod->VERSION;

my $log_fn= sub { $log->can($_[0])->($log, $_[1]) };

sub test_basic {
	my $input= ascii();
	open my $input_fh, '<', \$input or die;
	my $d= new_ok( 'Data::TableReader::Decoder::CSV',
		[ file_name => '', file_handle => $input_fh, _log => $log_fn ],
		'CSV decoder' );

	ok( my $iter= $d->iterator, 'got iterator' );

	is_deeply( $iter->(), [ 'a', 'b', 'c', 'd' ], 'first row' );
	is_deeply( $iter->(), [ '1', '2', '3', '4' ], 'second row' );
	is_deeply( $iter->(), undef, 'no third row' );
	ok( $iter->seek(0), 'rewind' );
	is_deeply( $iter->(), [ 'a', 'b', 'c', 'd' ], 'first row again' );
	is_deeply( $iter->([2,1]), [ '3', '2' ], 'slice from second row' );
	ok( !$iter->next_dataset, 'no next dataset' );
}

sub test_multi_iterator {
	my $input= ascii();
	open my $input_fh, '<', \$input or die;
	my $d= new_ok( 'Data::TableReader::Decoder::CSV',
		[ file_name => '', file_handle => $input_fh, _log => $log_fn ],
		'CSV decoder' );

	ok( my $iter= $d->iterator, 'create first iterator' );
	
	# This might be supported in the future, but for now ensure it dies
	like( (try { $d->iterator } catch {$_}), qr/multiple iterator/i, 'error for multiple iterators' );

	undef $iter; # release old iterator, freeing up the file handle to create a new one
	ok( $iter= $d->iterator, 'new iterator' );
	is_deeply( $iter->(), [ 'a', 'b', 'c', 'd' ], 'first row again' );
}

sub test_utf_bom {
	for my $input_fn (qw( utf8_bom utf16_le_bom utf16_be_bom utf8_nobom deceptive_utf8_nobom )) {
		subtest "seekable $input_fn" => sub {
			my $input= main->$input_fn;
			open my $input_fh, '<', \$input or die;
			my $d= new_ok( 'Data::TableReader::Decoder::CSV',
				[ file_name => '', file_handle => $input_fh, _log => $log_fn ],
				"CSV decoder for $input_fn" );
			ok( my $iter= $d->iterator, 'got iterator' );
			like( $iter->()[0], qr/^\x{FFFD}?test$/, 'first row' );
			is_deeply( $iter->(), [ "\x{8A66}\x{3057}", 1, 2, 3 ], 'second row' );
			is_deeply( $iter->(), [ "\x{27000}" ], 'third row' );
			is_deeply( $iter->(), undef, 'no fourth row' );
			ok( $iter->seek(0), 'rewind' );
			
			# workaround for a perl bug!  the input string gets corrupted
			substr($input,0,8)= substr(main->$input_fn,0,8);
			
			like( $iter->()[0], qr/^\x{FFFD}?test$/, 'first row' );
			is_deeply( $iter->([0,3]), [ "\x{8A66}\x{3057}", 3 ], 'slice from second row' );
			ok( !$iter->next_dataset, 'no next dataset' );
		};
		subtest "nonseekable $input_fn" => sub {
			my $input= main->$input_fn;
			pipe(my ($input_fh, $out_fh)) or die "pipe: $!";
			print $out_fh $input or die "print(pipe_out): $!";
			close $out_fh or die "close: $!";
			my $d= new_ok( 'Data::TableReader::Decoder::CSV',
				[ file_name => '', file_handle => $input_fh, _log => $log_fn ],
				"CSV decoder for $input_fn" );
			if ($input_fn =~ /deceptive/) {
				# Some inputs on non-seekable file handles will result in this exception.
				# This is expected.
				like( (try { $d->iterator } catch {$_}), qr/seek/, 'can\'t seek exception' );
			} else {
				ok( my $iter= $d->iterator, 'got iterator' );
				like( $iter->()[0], qr/^\x{FFFD}?test$/, 'first row' );
				is_deeply( $iter->(), [ "\x{8A66}\x{3057}", 1, 2, 3 ], 'second row' );
				is_deeply( $iter->(), [ "\x{27000}" ], 'third row' );
				is_deeply( $iter->(), undef, 'no fourth row' );
				ok( !$iter->next_dataset, 'no next dataset' );
			}
		};
	}
}

subtest basic => \&test_basic;
subtest multi_iter => \&test_multi_iterator;
subtest utf_bom => \&test_utf_bom;
done_testing;

sub ascii {
	return <<END;
a,b,c,d
1,2,3,4
END
}
sub utf8_bom {
	# BOM "test\n"
	# "\x{8A66}\x{3057},1,2,3\n"
	# "\x{27000}\n"
	return "\xEF\xBB\xBF"."test\n"."\xE8\xA9\xA6\xE3\x81\x97,1,2,3\n"."\xF0\xA7\x80\x80\n";
}
sub utf16_le_bom {
	return "\xFF\xFE"."t\0e\0s\0t\0\n\0"."\x66\x8A\x57\x30,\x001\x00,\x002\x00,\x003\x00\n\x00"."\x5C\xD8\x00\xDC\n\0";
}
sub utf16_be_bom {
	return "\xFE\xFF"."\x00t\x00e\x00s\x00t\x00\n"."\x8A\x66\x30\x57\x00,\x001\x00,\x002\x00,\x003\x00\n"."\xD8\x5C\xDC\x00\0\n";
}
sub utf8_nobom {
	return "test\n"."\xE8\xA9\xA6\xE3\x81\x97,1,2,3\n"."\xF0\xA7\x80\x80\n";
}
sub deceptive_utf8_nobom {
	return "\xEF\xBF\xBD"."test\n"."\xE8\xA9\xA6\xE3\x81\x97,1,2,3\n"."\xF0\xA7\x80\x80\n";
}