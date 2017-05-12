#!/usr/bin/env perl -w
use strict;
use Test;
use Digest::MD5;
use Digest::SHA1;

BEGIN { plan tests => 5 }

use Crypt::KDF::KDF2Generator; ok(1);

my $kdf=Crypt::KDF::KDF2Generator->new(-digest => 'Digest::MD5', -seed => 'Hello World!'); 
if('98187fc736a72d44a4172b39217c34c0531983e0' eq $kdf->kdf_hex(20)) { ok(2); }

$kdf=Crypt::KDF::KDF2Generator->new(-digest => 'Digest::MD5', -seed => 'Hello World!', -iv => 'S3cr3t'); 
if('dc5bb51dd387a3439568a038f90f0303c8495288' eq $kdf->kdf_hex(20)) { ok(3); }

$kdf=Crypt::KDF::KDF2Generator->new(-digest => 'Digest::SHA1', -seed => 'Hello World!'); 
if('1a7ef6c34ed965f6aa5ca246fc5c88ce68f47ae4' eq $kdf->kdf_hex(20)) { ok(4); }

$kdf=Crypt::KDF::KDF2Generator->new(-digest => 'Digest::SHA1', -seed => 'Hello World!', -iv => 'S3cr3t'); 
if('19e023e1c9579d29666fce044a60fe01b449f278' eq $kdf->kdf_hex(20)) { ok(5); }
exit;

__END__
