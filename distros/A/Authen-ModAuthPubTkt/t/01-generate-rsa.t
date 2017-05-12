use strict;
use warnings;

use Test::More ;

plan tests => 2;

use Authen::ModAuthPubTkt;

##
## Generate a ticket, with RSA key file.
##
my $ticket = pubtkt_generate(
			privatekey => "t/test_keys/rsa.priv.pem",
			keytype => "rsa",
			clientip => "127.0.0.1",
			userid => "gordon",
			validuntil => 1337899939,
			graceperiod => 3600 );
pass("generate-rsa");


##
## Since all the parameters are fixed (including the "validuntil") - the ticket should be this:
##
my $expected_ticket = "uid=gordon;cip=127.0.0.1;validuntil=1337899939;graceperiod=1337896339;tokens=;udata=;sig=USi6pjiAPXxHllroEsO0rrrhQBfp5mYQp66YvErlA3mYpaVxWjV2KhSmHxj+LntfDYuxg0bvXlCxtUxk5QxFhddzeJZHa9tVY0FkVi1cG4o+AaXDPDVwurf3CWxNiHVaeYyTcETXAIZiQ+xECs68g8y/rWwtTAJqIQKCiuDepJQ=";

is ( $ticket, $expected_ticket, "generate-rsa-expected-ticket") ;

