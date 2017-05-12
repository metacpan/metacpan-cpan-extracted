#!/usr/bin/perl

use Test::More tests => 13;
use File::Spec::Functions qw(:ALL);

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };

my $base   = 'certs';
my $pass   = 'testing';

my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file(catdir($base, 'test.p12'));

ok($pkcs12);

my $pemcert = $pkcs12->certificate($pass);

ok($pemcert);

my $pemkey = $pkcs12->private_key($pass);

ok($pemkey);

ok($pkcs12->mac_ok($pass));

ok($pkcs12->as_string);

# try changing the password
ok($pkcs12->changepass($pass, 'foo'));

ok($pkcs12->mac_ok('foo'));

ok($pkcs12->changepass('foo', $pass));

# Try creating a PKCS12 file.
my $outfile = catdir($base, 'out.p12');

ok($pkcs12->create(
	catdir($base, 'test-cert.pem'),
	catdir($base, 'test-key.pem'),
	$pass,
	$outfile,
	"Friendly Name"
));

ok(-f $outfile);

my $created = Crypt::OpenSSL::PKCS12->new_from_file($outfile);

ok($created);

ok($created->mac_ok($pass));

unlink $outfile;
