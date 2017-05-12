
use strict;
use Authen::SASL qw(XS); # Only use XS plugin
use Test::Simple tests => 5;

our $me;
require "t/common.pl";

pipe (FROM_CLIENT,TO_PARENT) or die "pipe failed.";
pipe (FROM_PARENT,TO_CLIENT) or die "pipe failed.";

my $pid = fork();
my $mech = "PLAIN";
my $service = "arc";
my $host = "hyade11.ifh.de";

if ($pid) { # parent
sleep(1);
	close FROM_PARENT;
	close TO_PARENT;
	$me = "server";


	my $sasl = Authen::SASL->new (
		mechanism => $mech,
		callback => {
			canonuser => \&canonuser,		
			authorize => \&authorize,
			getsecret => \&getsecret,
			checkpass => \&checkpass,
		}
	) or ok(0);
	ok(1);
	
	my $conn = $sasl->server_new($service) or die "Authen::SASL::XS failed." or
		ok(0);
	ok(1);

	print $conn->listmech("","|",""),"\n";

	sendreply( $conn->server_start( getreply(\*FROM_CLIENT)  ),\*TO_CLIENT );
	ok(1);
	
	while ($conn->need_step) {
		sendreply( $conn->server_step( &getreply(\*FROM_CLIENT) ) ,\*TO_CLIENT );
	}

	if ($conn->code == 0) {
		ok(1);
		print "Server: Test successful Negotiation succeeded.\n";
	} else {
		ok(0);
		print "Server: Negotiation failed.\n",$conn->error(),"\n";
	}

	close FROM_CLIENT;
	close TO_CLIENT;
	wait();
} elsif ($pid == 0) {
	close FROM_CLIENT;
	close TO_CLIENT;
	$me = "client";

	my $sasl = Authen::SASL->new (
		mechanism => $mech,
		callback => {
			user => \&getusername,
			pass => \&getpassword,
			auth => \&getauthname,
		}
	) or die "Authen::SASL failed.";

	my $conn = $sasl->client_new($service, $host)
		or die "Authen::SASL::XS failed.";

	sendreply($conn->client_start(),*TO_PARENT);

	while ($conn->need_step) {
		sendreply($conn->client_step( &getreply(*FROM_PARENT) ),*TO_PARENT );
	}
					   
	if ($conn->code == 0) {
		print "Client: Negotiation succeeded.\n";
	} else { 
		print "Client: Negotiation failed.\n",$conn->error,"\n";
	}
	
	close FROM_PARENT;
	close TO_PARENT;
	exit 0;
} else {
	exit 1;
}

ok(1);

exit 0;
