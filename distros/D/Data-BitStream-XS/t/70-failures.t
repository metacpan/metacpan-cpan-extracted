#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::BitStream::XS qw(code_is_universal);

plan tests => 41;

is( code_is_universal('~~~~~'), undef, "is_universal with unknown code returns undef");

eval { my $v = Data::BitStream::XS->new(100); };
like($@, qr/hash/i, "new needs to take a hash");

eval { my $v = Data::BitStream::XS->new(mode=>'wrong'); };
like($@, qr/unknown mode/i, "Incorrect mode");

my $v = Data::BitStream::XS->new;
is($v->writing, 1, "writing mode");

my $val = 117;
$v->put_gamma($val);
my $len = $v->len;


eval { $v->code_put('~~~~~'); };
like($@, qr/Unknown code/i, "Invalid code for code_put");
eval { $v->code_put('Gamma(2)'); };
like($@, qr/does not have parameters/, "code_put with Gamma parameters");
eval { $v->code_put('Rice'); };
like($@, qr/needs .* parameter/, "code_put with Rice no parameters");

eval { $v->code_get('~~~~~'); };
like($@, qr/Unknown code/i, "Invalid code for code_get");
eval { $v->code_get('Gamma(2)'); };
like($@, qr/does not have parameters/, "code_get with Gamma parameters");
eval { $v->code_get('Rice'); };
like($@, qr/needs .* parameter/, "code_get with Rice no parameters");

eval { $v->write(0, 2); };
like($@, qr/invalid param.*bits/, "write invalid bits: 0");
eval { $v->write(-4, 2); };
like($@, qr/invalid param.*bits/, "write invalid bits: -4");
eval { $v->write(1025, 2); };
like($@, qr/invalid param.*bits/, "write invalid bits: 1025");


eval { $v->rewind; };
like($@, qr/rewind while writing/, "rewind while writing");

eval { $v->exhausted; };
like($@, qr/exhausted while writing/, "exhausted while writing");

eval { $v->skip(3); };
like($@, qr/skip while writing/, "skip while writing");

eval { $v->read(3); };
like($@, qr/read while writing/, "read while writing");
eval { $v->readahead(3); };
like($@, qr/read while writing/, "readahead while writing");
eval { $v->read_string(3); };
like($@, qr/read while writing/, "read_string while writing");

eval { $v->get_gamma; };
like($@, qr/read while writing/, "get_gamma while writing");



$v->rewind_for_read;
eval { $v->read(0); };
like($@, qr/invalid param.*bits/, "read invalid bits: 0");
eval { $v->read(-4); };
like($@, qr/invalid param.*bits/, "read invalid bits: -4");
eval { $v->read(1025); };
like($@, qr/invalid param.*bits/, "read invalid bits: 1025");

eval { $v->readahead(0); };
like($@, qr/invalid param.*bits/, "readahead invalid bits: 0");
eval { $v->readahead(-4); };
like($@, qr/invalid param.*bits/, "readahead invalid bits: -4");
eval { $v->readahead(1025); };
like($@, qr/invalid param.*bits/, "readahead invalid bits: 1025");

eval { $v->read_string(-3); };
like($@, qr/invalid param.*bits/, "read_string invalid bits: -3");
is( $v->read_string(0), "", "read_string(0) returns empty string");
eval { $v->read_string(1000); };
like($@, qr/short read/, "read string with too many bits");

eval { $v->get_binword(0); };
like($@, qr/invalid parameters/, "get_binword invalid bits: 0");
eval { $v->get_binword(-4); };
like($@, qr/invalid parameters/, "get_binword invalid bits: -4");
eval { $v->get_binword(1025); };
like($@, qr/invalid parameters/, "get_binword invalid bits: 1025");

eval { $v->get_baer(-33); };
like($@, qr/invalid parameters/, "baer invalid bits: -33");
eval { $v->get_baer( 33); };
like($@, qr/invalid parameters/, "baer invalid bits:  33");

eval { $v->get_boldivigna(0); };
like($@, qr/invalid parameters/, "boldivigna invalid bits:  0");
eval { $v->get_boldivigna(16); };
like($@, qr/invalid parameters/, "boldivigna invalid bits: 16");

eval { $v->write(3, 1); };
like($@, qr/write while reading/, "write while reading");
eval { $v->put_string('101'); };
like($@, qr/write while reading/, "put_string while reading");

eval { $v->put_gamma; };
like($@, qr/write while reading/, "put_gamma while reading");

eval { $v->skip(64); };
like($@, qr/skip off stream/, "skip off stream");


is( $v->get_gamma, $val, "Successfully read our value");

# put_stream
# startstepstop
# startstop
# rice/golomb/arice subs
