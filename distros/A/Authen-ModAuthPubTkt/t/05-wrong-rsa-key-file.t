use strict;
use warnings;

use Test::More ;

plan tests => 2;

use Authen::ModAuthPubTkt;

##
## Generate a ticket, with RSA key file.
##
my $ticket = pubtkt_generate(
			privatekey => "t/test_keys/rsa.priv2.pem",
			keytype => "rsa",
			clientip => "127.0.0.1",
			userid => "gordon",
			validuntil => time() + 86400,
			graceperiod => 3600 );
pass("generate-rsa");

##
## Now verify it, using a WRONG public key. - should not be OK
##
my $ok = pubtkt_verify(
		publickey => "t/test_keys/rsa.pub.pem",
		keytype => "rsa",
		ticket => $ticket );
ok ( ! $ok, "verify-rsa-wrong-key-file" );

