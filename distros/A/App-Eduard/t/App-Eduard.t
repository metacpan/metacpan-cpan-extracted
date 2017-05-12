#!/usr/bin/perl -w
use strict;
use warnings;

use constant KEYID => '34B22806';
use constant EMAIL => 'Eduard (Key for testing Eduard) <eduard@ceata.org>';

use File::Copy qw/cp/;
use File::Temp qw/tempdir/;
use Test::More tests => 25;
BEGIN { use_ok('App::Eduard', qw/import_pubkeys process_message/) };

umask 0077; # GPG doesn't like group-/world-readable homedirs
$ENV{EDUARD_DEBUG} = $ENV{TEST_VERBOSE};
$ENV{EDUARD_KEYDIR} = tempdir 'App-Eduard-test.XXXX', TMPDIR => 1, CLEANUP => 1;
cp "t/keydir/$_", $ENV{EDUARD_KEYDIR} for qw/pubring.gpg secring.gpg/;

my $contains_pubkey = App::Eduard::mp->parse_open('t/data/contains-pubkey');
my @keys = import_pubkeys ($contains_pubkey, App::Eduard::mg);
is $keys[0], 'DE12658069C2F09BF996CC855AAF79E969137654', 'import_pubkeys';

my ($tmpl, %params);

sub process {
	my ($name, $expected) = @_;
	($tmpl, %params) = process_message("t/data/$name");
	is $tmpl, $expected, "Result for $name is $expected" or diag "GnuPG said: $params{message}"
}

process 'mime-signed', 'sign';
is $params{keyid}, KEYID, 'mime-signed keyid';
is $params{email}, EMAIL, 'mime-signed email';

process 'mime-encrypted', 'encrypt';
like $params{plaintext}, qr/MIME encrypted/, 'mime-encrypted plaintext';

process 'mime-signed-encrypted', 'signencrypt';
is $params{keyid}, KEYID, 'mime-signed-encrypted keyid';
is $params{email}, EMAIL, 'mime-signed-encrypted email';
like $params{plaintext}, qr/MIME signed & encrypted/, 'mime-signed-encrypted plaintext';

process 'inline-signed', 'sign';
is $params{keyid}, KEYID, 'inline-signed keyid';
is $params{email}, EMAIL, 'inline-signed email';

process 'inline-encrypted', 'encrypt';
like $params{plaintext}, qr/Inline encrypted/, 'inline-encrypted plaintext';

process 'inline-signed-encrypted', 'signencrypt';
is $params{keyid}, KEYID, 'inline-signed-encrypted keyid';
is $params{email}, EMAIL, 'inline-signed-encrypted email';
like $params{plaintext}, qr/Inline signed & encrypted/, 'inline-signed-encrypted plaintext';

process 'inline-signed-attachment', 'sign';
is $params{keyid}, KEYID, 'inline-signed-attachment keyid';
is $params{email}, EMAIL, 'inline-signed-attachment email';

process 'inline-encrypted-attachment', 'encrypt';
like $params{plaintext}, qr/Inline encrypted/, 'inline-encrypted plaintext';
