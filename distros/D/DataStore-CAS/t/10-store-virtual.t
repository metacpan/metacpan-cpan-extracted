#! /usr/bin/env perl -T
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Path::Class;
use Data::Dumper;
use File::stat;

sub dies(&$) {
	my ($code, $comment)= @_;
	try {
		&$code;
		fail "Failed to die during '$comment'";
	}
	catch {
		ok "died - $comment";
	};
}
sub dies_like(&$$) {
	my ($code, $pattern, $comment)= @_;
	try {
		&$code;
		fail "Failed to die during '$comment'";
	}
	catch {
		like($_, $pattern, $comment);
	};
}

use_ok('DataStore::CAS::Virtual') || BAIL_OUT;

my $cas= DataStore::CAS::Virtual->new();
is( $cas->hash_of_null, 'da39a3ee5e6b4b0d3255bfef95601890afd80709', 'null hash (sha1)' );

$cas= DataStore::CAS::Virtual->new( digest => 'MD5' );
is( $cas->hash_of_null, 'd41d8cd98f00b204e9800998ecf8427e', 'null hash (md5)' );

my $str= 'Testing Testing Testing';
my $hash= 'd6bb5107d7bf572751db734847db1bc7';
is( $cas->put($str), $hash, 'put' );
ok( my $f= $cas->get($hash)->open, 'get/open' );
is( scalar(<$f>), $str, 'read contents' );

done_testing;
