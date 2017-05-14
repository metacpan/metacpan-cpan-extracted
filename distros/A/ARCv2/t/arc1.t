use Test::More tests => 17;
use strict;

# To work as a client/server we have to fork

my $pid = fork();

my $user = "mannfred";
my $pass = "klaus";

if ($pid == 0) { # Child
	
	use Arc::Server;
	use Arc::Connection::Server;

	my $server = new Arc::Server (
				loglevel => 0,
				logdestination => 'stderr',
				server => {
					port => [30001], # Testport
					host => "localhost", 
				},
				connection_vars => {
					loglevel => 0,
					logdestination => 'stderr',
					sasl_mechanisms => ['PLAIN'],
					sasl_cb_checkpass => \&checkpass,
					sasl_cb_getsecret => \&getsecret,
					service => "arc",
					commands => { 
						test => 'Arc::Command::Test',
						whoami => 'Arc::Command::Whoami',
						uptime => 'Arc::Command::Uptime',
					}
				}
	);

	$server->Start();

	exit 0;
} elsif ($pid) { # Parent
	use Arc::Connection::Client;
	ok(1); #1
	
	sleep(3); # Wait for the server to get ready

	my $client = new Arc::Connection::Client (
				server => "localhost",
				port => 30001, # Testport
				loglevel => 0,
				logdestination => 'stderr',
				service => 'arc',
				sasl_mechanism => "PLAIN",
				sasl_cb_user => $user,
				sasl_cb_auth => $user,
				sasl_cb_pass => $pass,
	) or ok(0);
	ok(1); #2

	my $s; 
	if ($client->StartSession()) { ok(1); } else { ok(0); } #3

	if ($client->CommandStart("test")) { ok(1); } else { ok(0); } #4
	if ($client->CommandWrite("hallo\n")) { ok(1); } else { ok(0); } #5
	if ($s = $client->CommandRead()) { ok(1); } else { ok(0); } #5
	if ($s eq "all\n") { ok(1); } else { ok(0); } #6
	if ($client->CommandEnd()) { ok(1); } else { ok(0); } #7
	
	if ($client->CommandStart("whoami")) { ok(1); } else { ok(0); }
	if ($s = $client->CommandRead()) { ok(1); } else { ok(0); }
	if ($client->CommandEnd()) { ok(1); } else { ok(0); }
	
	if ($client->CommandStart("uptime")) { ok(1); } else { ok(0); }
	if ($s = $client->CommandRead()) { ok(1); } else { ok(0); }
	if ($s =~ /load average/) { ok(1); } else { ok(0); }
	if ($client->CommandEnd()) { ok(1); } else { ok(0); }
	print $s;
	
	if ($client->Quit()) { ok(1); } else { ok(0); }

	kill 'INT', $pid;

	wait();
} else {
	ok(0);
}
ok(1);

exit 0;


sub checkpass
{
	my ($user,$vpass) = @_;
	return ($vpass eq $pass);
}

sub getsecret
{
	return $pass;
}





