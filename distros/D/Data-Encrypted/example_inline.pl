#!/usr/bin/perl -w

use lib "blib/lib";
use strict;

use Data::Encrypted;
use Inline::Files;

open(ENCRYPT, "+<") or die $!;

my $enc = new Data::Encrypted FH => \*ENCRYPT;
my $password = $enc->encrypted("password");

print "Password entered: $password\n";

__ENCRYPT__
-----BEGIN COMPRESSED RSA ENCRYPTED MESSAGE-----
Scheme: Crypt::RSA::ES::OAEP
Version: 1.24

eJwBkQBu/zEwADEyOABDeXBoZXJ0ZXh0XEOHtahmRkU0b1ozgOd78+vYHZYEvm+AZQKuzAEtVBIo
KxTiELI8lEs2sGg/sKolYf52WaRokumifk+etn8clo1w50RTEtYUrG43740aIf03DtlXOuzBRSBU
LzjKFUMRjqybrCl47IjsJ2y0cWRnc59s3ucciZXLyEnPoOKFm8hGW0Hf
=HABz06hp32FlFBpFeJK1bw==
-----END COMPRESSED RSA ENCRYPTED MESSAGE-----

