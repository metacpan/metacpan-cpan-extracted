#! /usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Crypt::PK::ECC::Schnorr') };

use Digest::SHA qw(sha256);

my $pk = Crypt::PK::ECC::Schnorr->new;
$pk->generate_key("secp256k1");

my $message = sha256("Some message");
my $sign = $pk->sign_message($message);

my $pk2 = Crypt::PK::ECC::Schnorr->new;
$pk2->import_key_raw($pk->export_key_raw("public_compressed"), "secp256k1");
ok($pk2->verify_message($message, $sign));
