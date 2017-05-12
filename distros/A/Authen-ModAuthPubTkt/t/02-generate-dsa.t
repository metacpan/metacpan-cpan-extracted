use strict;
use warnings;

use Test::More ;

plan tests => 1;

use Authen::ModAuthPubTkt;

##
## Generate a ticket, with RSA key file.
##
my $ticket = pubtkt_generate(
			privatekey => "t/test_keys/dsa.priv.pem",
			keytype => "dsa",
			clientip => "127.0.0.1",
			userid => "gordon",
			validuntil => 1337899939,
			graceperiod => 3600 );
pass("generate-dsa");
