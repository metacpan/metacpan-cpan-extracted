#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN {
	use_ok('Compress::LZW::Progressive');
}

use Compress::LZW::Progressive;

my $codec = Compress::LZW::Progressive->new( bits => 12 );

isa_ok($codec, 'Compress::LZW::Progressive');

my $str1 = "<stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' to='foo.com' version='1.0'>";
my $str2 = "<stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'><required/></starttls><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism></mechanisms></stream:features>";

# Do simple test
my $lzw = $codec->compress($str1);
my $plain = $codec->decompress($lzw);

ok($plain eq $str1, "Simple compress/decompress");

$codec->reset;

# Test concatenated decompression
for (0..40) {
	my $lzw1 = $codec->compress($str1);
	my $lzw2 = $codec->compress($str2);
	my $plain = $codec->decompress($lzw1.$lzw2);
	my $str = $str1.$str2;

	ok($plain eq $str, "Concatenated decompress");
}
$codec->reset;

# Create dict code deletion condition
my $deletes = $codec->{compress_deleted_least_used_codes};
while ($codec->{compress_deleted_least_used_codes} <= ($deletes + 1)) {
	my $str = join '', map { chr (int (rand 90) + 32) } 0..4000;
	my $lzw = $codec->compress($str);
	my $plain = $codec->decompress($lzw);

	ok($plain eq $str, "Random testing reset");
}
$codec->reset;
