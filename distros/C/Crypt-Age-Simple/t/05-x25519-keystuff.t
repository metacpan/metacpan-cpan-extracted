#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

use Crypt::Age::Simple qw< :x25519 >;

my ($public, $secret) = age_x25519_generate_keypair();
my $filetext = <<"END";
# created: 2026-08-11T16:13:15+02:00
# public key: $public
$secret
END

is age_x25519_extract_secret_key($filetext), $secret, 'extract secret key';
is age_x25519_extract_public_key($filetext), $public, 'extract public key';

done_testing();
