#!/usr/bin/env perl -w
use strict;
use Test;
use Digest::MD5;
use Digest::SHA1;

BEGIN { plan tests => 5 }

use Crypt::KDF::KDF1Generator; ok(1);

my $kdf=Crypt::KDF::KDF1Generator->new(-digest => 'Digest::MD5', -seed => 'Hello World!'); 
if('ed83afb6d55c8a982cb3993dd39a68d998187fc7' eq $kdf->kdf_hex(20)) { ok(2); }

$kdf=Crypt::KDF::KDF1Generator->new(-digest => 'Digest::MD5', -seed => 'Hello World!', -iv => 'S3cr3t'); 
if('56efd51a41bd4ca780b377763a4afdb9dc5bb51d' eq $kdf->kdf_hex(20)) { ok(3); }

$kdf=Crypt::KDF::KDF1Generator->new(-digest => 'Digest::SHA1', -seed => 'Hello World!'); 
if('23ec569323b08240bdcb0e14f3abaad5ef545cdd' eq $kdf->kdf_hex(20)) { ok(4); }

$kdf=Crypt::KDF::KDF1Generator->new(-digest => 'Digest::SHA1', -seed => 'Hello World!', -iv => 'S3cr3t'); 
if('e8dd95240d6922ee5eb3011099c5147ddacf7843' eq $kdf->kdf_hex(20)) { ok(5); }

exit;

__END__
