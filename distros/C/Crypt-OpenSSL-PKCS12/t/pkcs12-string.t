#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 29;
use File::Spec::Functions qw(:ALL);
use Data::Dumper;
use Crypt::OpenSSL::Guess;

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };

{
    my $certdata = "тест";
    is length $certdata, 8;
    utf8::decode($certdata);
    is length $certdata, 4;
    local $@;
    eval {
        my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_string($certdata);
    };

    my $ok = $@ =~ /Source string must not be UTF-8 encoded/i;
    ok $ok, 'utf8 string refused new_from_string()';
}

{
    use utf8;
    my $certdata = "тест";
    is length $certdata, 4;
    local $@;
    eval {
        my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_string($certdata);
    };

    my $ok = $@ =~ /Source string must not be UTF-8 encoded/i;
    ok $ok, 'utf8 string refused in new_from_string()';
}

my $base   = 'certs';
my $pass   = 'testing';

my ($major, $minor, $patch) = openssl_version();

my $certfile;
if ($major le "1.1" )  {
    $certfile = catdir($base, 'test_le_1.1.p12');
} else {
    $certfile = catdir($base, 'test.p12');
}

diag("Attempting to read certificate string from file $certfile");

# first, make argument test
my @argtest = (
    [],    0, # 0 is for invalid argument type
    {},    0,
    undef, 0,
    \ "s", 0,
    0,     1, # 1 is for valid argument type
    0.01,  1,
    "str", 1,
);

for (my $i = 0; $i < @argtest; $i += 2) {
    my ($arg, $arg_ok_expected) = ($argtest[$i], $argtest[$i + 1]);
    eval { Crypt::OpenSSL::PKCS12->new_from_string($arg) };
    unless ($arg_ok_expected) {
        ok(!!($@ =~ /Invalid Perl type/));
    } else {
        # ignore SSL error; only argument type is for checking
        pass;
    }
}

# read file to string in Perl way
ok(open my $fh, '<', $certfile);

ok(binmode $fh);

my $certdata = do { undef $/; <$fh> };

ok(length $certdata);

ok(close $fh);

# make PKCS12 object from string
my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_string($certdata);

# run below code that is completely taken from the test pkcs12.t
ok($pkcs12, 'PKCS object created');

my $pemcert = $pkcs12->certificate($pass);

ok($pemcert, 'PEM certificate created');

my $pemkey = $pkcs12->private_key($pass);

ok($pemkey, 'Asserting PEM key');

ok($pkcs12->mac_ok($pass), 'Asserting mac');

ok($pkcs12->as_string, 'Asserting PKCS12 as string');

SKIP: {
    # https://github.com/openssl/openssl/issues/19092
    if ($major =~ /^3\./) {
        skip("OpenSSL 3.x cannot change pkcs12 passwords", 3);
    } else {
        # try changing the password
        ok($pkcs12->changepass($pass, 'foo'), 'Changing password');

        ok($pkcs12->mac_ok('foo'), 'Reasserting mac');

        ok($pkcs12->changepass('foo', $pass), 'Changing password again');
    }
}
# Try creating a PKCS12 file.
my $outfile = catdir($base, 'out.p12');

ok($pkcs12->create(
	catdir($base, 'test-cert.pem'),
	catdir($base, 'test-key.pem'),
	$pass,
	$outfile,
	'Friendly Name'
), 'Testing create based on PKCS12');

ok(-f $outfile);

my $created = Crypt::OpenSSL::PKCS12->new_from_file($outfile);

ok($created);

ok($created->mac_ok($pass), 'Reasserting new mac');

unlink $outfile;
