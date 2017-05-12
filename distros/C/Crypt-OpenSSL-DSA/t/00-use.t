# -*- Mode: Perl; -*-

# test file added by Brad Fitzpatrick in response to bugs found by Karl Koscher
# related to null bytes in SHA1 signatures, and strlen truncating the message
# being signed/verified

use strict;

use Test;
use Crypt::OpenSSL::DSA;

BEGIN { plan tests => 1 };

my $dsa = Crypt::OpenSSL::DSA->generate_parameters( 512 );
$dsa->generate_key;

ok(1);
