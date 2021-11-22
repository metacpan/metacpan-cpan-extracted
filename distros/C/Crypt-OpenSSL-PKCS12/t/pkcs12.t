#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 16;
use File::Spec::Functions qw(:ALL);
use Data::Dumper;

BEGIN { use_ok('Crypt::OpenSSL::PKCS12') };

my $base   = 'certs';
my $pass   = 'testing';

my $certfile = catdir($base, 'test.p12');

diag("Attempting to read certificate from $certfile");

my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file($certfile);

ok($pkcs12, 'PKCS object created');

my $pemcert = $pkcs12->certificate($pass);

ok($pemcert, 'PEM certificate created');

my $pemkey = $pkcs12->private_key($pass);

ok($pemkey, 'Asserting PEM key');

ok($pkcs12->mac_ok($pass), 'Asserting mac');

ok($pkcs12->as_string, 'Asserting PKCS12 as string');

# try changing the password
ok($pkcs12->changepass($pass, 'foo'), 'Changing password');

ok($pkcs12->mac_ok('foo'), 'Reasserting mac');

ok($pkcs12->changepass('foo', $pass), 'Changing password again');

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

my $pksc12_data = $pkcs12->create_as_string(
	catdir($base, 'test-cert.pem'),
	catdir($base, 'test-key.pem'),
	$pass,
	"Friendly Name"
);

ok($pksc12_data);

$created = Crypt::OpenSSL::PKCS12->new_from_string($pksc12_data);

ok($created);

ok($created->mac_ok($pass));
