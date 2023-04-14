#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase;

use lib 't/lib';

my @tests = (
	[ 'MD5::Hex', '098f6bcd4621d373cade4e832627b4f6' ],
	[ 'SHA1::Hex', 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3' ],
	[ 'MD5::Base64', 'CY9rzUYh03PK3k6DJie09g' ],
	[ 'SHA1::Base64', 'qUqP5cyxm6YcTAhz05Hph5gvu9M' ],
);

my $passphrase = Crypt::Passphrase->new(
	encoder => 'Reversed',
	validators => [ map { $_->[0]} @tests ],
);

for my $test (@tests) {
	my ($short_name, $hash) = @$test;
	(my $file = $short_name) =~ s{(\w+)::(\w+)}{Crypt/Passphrase/$1/$2.pm};
	require $file;
	my $module = "Crypt::Passphrase::$short_name";
	my $object = $module->new;
	ok($object->accepts_hash($hash), "$short_name accepts hash $hash");
	ok($object->verify_password('test', $hash), "$short_name verifies hash $hash");
	ok($passphrase->verify_password('test', $hash), "$short_name verifies hash $hash throught C::P too");
	ok($passphrase->needs_rehash($hash), "$hash needs rehash");
}

done_testing;
