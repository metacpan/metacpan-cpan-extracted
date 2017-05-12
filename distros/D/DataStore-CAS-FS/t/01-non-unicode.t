#! /usr/bin/env perl -T
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use JSON;

use_ok('DataStore::CAS::FS::InvalidUTF8') || BAIL_OUT;

subtest json_encode_decode => sub {
	my $j= JSON->new()->convert_blessed
		->filter_json_single_key_object(
			'*InvalidUTF8*' => \&DataStore::CAS::FS::InvalidUTF8::FROM_JSON
		);

	my $x= DataStore::CAS::FS::InvalidUTF8->decode_utf8("\x{FF}");
	my $json= $j->encode($x);
	my $x2= "".$j->decode($json);
	is( $x, $x2 );
	ok( !utf8::is_utf8($x2) );
	ok( ref $x2 );
	$x2= "$x2";
	ok( !ref $x2 );
	done_testing;
};

subtest concat => sub {
	isa_ok( my $x= DataStore::CAS::FS::InvalidUTF8->decode_utf8("\xEA\xB0"), 'DataStore::CAS::FS::InvalidUTF8' );
	isa_ok( my $y= DataStore::CAS::FS::InvalidUTF8->decode_utf8("\x80"), 'DataStore::CAS::FS::InvalidUTF8' );
	is( $x.$y, "\x{AC00}" );
	done_testing;
};

done_testing;