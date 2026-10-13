#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use File::Temp qw< tempfile >;

use Crypt::Age::Simple qw< :x25519 >;

can_ok __PACKAGE__, qw< age_x25519_decrypt age_x25519_encrypt  >;

my ($public, $secret) = age_x25519_generate_keypair();
my $cleartext = 'foo that bar!';

my ($ifh, $original) = tempfile(UNLINK => 1);
binmode $ifh, ':raw';
print {$ifh} $cleartext;
close $ifh;

$ifh = undef;
open $ifh, '<', $original or die "open($original): $!";
my ($efh, $encrypted) = tempfile(UNLINK => 1);
lives_ok { age_x25519_encrypt_fh($public, $ifh, $efh) }
   'encrypt to filehandle';
close $efh;
close $ifh;
ok -s $encrypted, 'encrypted file was generated';

$efh = undef;
open $efh, '<', $encrypted or die "open($encrypted): $!";
my ($ofh, $decrypted) = tempfile(UNLINK => 1);
lives_ok { age_x25519_decrypt_fh([$secret], $efh, $ofh) }
   'decrypt to filehandle';
close $ofh;
close $efh;
ok -s $decrypted, 'decrypted file was generated';

my $retrieved = do { local(@ARGV, $/) = $decrypted; <> };
is $retrieved, $cleartext, 'decryption was successful across files';

done_testing();
