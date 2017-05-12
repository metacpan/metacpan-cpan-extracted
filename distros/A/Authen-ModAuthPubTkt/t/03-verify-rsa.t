use strict;
use warnings;

use Test::More ;

plan tests => 102;

use Authen::ModAuthPubTkt;

##
## Generate a ticket, with RSA key file.
##
my $ticket = pubtkt_generate(
			privatekey => "t/test_keys/rsa.priv.pem",
			keytype => "rsa",
			clientip => "127.0.0.1",
			userid => "gordon",
			validuntil => time() + 86400,
			graceperiod => 3600 );
pass("generate-rsa");


##
## Now verify it
##
my $ok = pubtkt_verify(
		publickey => "t/test_keys/rsa.pub.pem",
		keytype => "rsa",
		ticket => $ticket );
ok ( $ok, "verify-rsa" );

##
## Change random characters in the ticket, make sure it fails.
##
warn "!! NOTE:: Some warning may be printed below, as we're detecting invalid keys. This is expected\n";
foreach ( 1..100 ) {

	my $bad_ticket;
	do {
		$bad_ticket = $ticket ;

		# replace one random character
		substr($bad_ticket, int(rand(length($ticket)-2)),1, chr(int(rand(92))+32));
	} while  ($bad_ticket eq $ticket);

	my $bad_key_verified;
	eval {
		$bad_key_verified = pubtkt_verify(
			publickey => "t/test_keys/rsa.pub.pem",
			keytype => "rsa",
			ticket => $bad_ticket );
	};
	if ($bad_key_verified) {
		warn "Bad key passed verification!\n";
		warn "good-ticket:\n$ticket\n";
		warn "bad-ticket:\n$bad_ticket\n";
	}
	ok ( ! $bad_key_verified, "verify-rsa-bad-key" );
}
