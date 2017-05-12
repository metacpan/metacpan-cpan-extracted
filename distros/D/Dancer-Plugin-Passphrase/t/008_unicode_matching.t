use Test::More tests => 8;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;
use Encode;

# Unicode Character 'PILE OF POO'.
my $secret      = "\x{1F4A9}";
my $utf8_secret = Encode::encode_utf8("\x{1F4A9}");


# SHA-1 Tests
my $sha_utf8 = passphrase($utf8_secret)->generate({ algorithm => 'SHA-1' })->rfc2307;

ok(passphrase($utf8_secret)->matches($sha_utf8),  'UTF8 matches UTF8 for SHA-1');
eval { passphrase($secret)->generate({ algorithm => 'SHA-1' })->rfc2307; };
like $@, qr/Wide character in subroutine entry/i, 'SHA-1 needs encoded text';


# SHA-256 Tests
my $sha_256_utf8 = passphrase($utf8_secret)->generate({ algorithm => 'SHA-256' })->rfc2307;

ok(passphrase($utf8_secret)->matches($sha_256_utf8),  'UTF8 matches UTF8 for SHA-256');
eval { passphrase($secret)->generate({ algorithm => 'SHA-256' })->rfc2307; };
like $@, qr/Wide character in subroutine entry/i, 'SHA-256 needs encoded text';


# MD5 Tests
my $md5_utf8 = passphrase($utf8_secret)->generate({ algorithm => 'MD5' })->rfc2307;

ok(passphrase($utf8_secret)->matches($md5_utf8),  'UTF8 matches UTF8 for MD5');
eval { passphrase($secret)->generate({ algorithm => 'MD5' })->rfc2307; };
like $@, qr/Wide character in subroutine entry/i, 'MD5 needs encoded text';


# Bcrypt Tests
my $bcrypt_utf8 = passphrase($utf8_secret)->generate({ algorithm => 'Bcrypt' })->rfc2307;

ok(passphrase($utf8_secret)->matches($bcrypt_utf8),  'UTF8 matches UTF8 for Bcrypt');
eval { passphrase($secret)->generate({ algorithm => 'Bcrypt' })->rfc2307; };
like $@, qr/input must contain only octets/i, 'Bcrypt needs encoded text';
