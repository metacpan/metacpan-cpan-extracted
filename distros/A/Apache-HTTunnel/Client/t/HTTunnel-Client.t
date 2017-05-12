use strict ;
use Test ;
use URI ;

BEGIN {
	my $nb_tests = 0 ;
	if (! $HTTunnel::Client::Test::URL){
		$HTTunnel::Client::Test = 1 ;
		$HTTunnel::Client::Test::ExtraTests = 0 ;

		if (! open(URL, "<t/server_url")){
			plan(tests => 1) ;
			skip("'t/server_url' file not found", 1) ;
			exit() ;
		}
		$HTTunnel::Client::Test::URL = <URL> ;
		chomp($HTTunnel::Client::Test::URL) ;
		close(URL) ;
		if (! $HTTunnel::Client::Test::URL){
			plan(tests => 1) ;
			skip("empty Apache::HTTunnel server URL", 1) ;
			exit() ;
		}
		print STDERR "\nApache::HTTunnel server URL is $HTTunnel::Client::Test::URL\n" ;
	}

	plan(tests => 7 + $HTTunnel::Client::Test::ExtraTests) ;
}

if ($ENV{PERL_HTTUNNEL_TEST_JAVA}){
	print STDERR "\n" unless $HTTunnel::Client::Test ;
	print STDERR "Using Java client.\n" ;
	require Inline::Java ;
	Inline->bind(
		Java => 'blib/lib/HTTunnel/Client.java',
	) ;
}
else {
	require HTTunnel::Client ;
}
ok(1) ;

# Regular usage
my $hc = new HTTunnel::Client($HTTunnel::Client::Test::URL) ;
my $uri = new URI($HTTunnel::Client::Test::URL) ;

ok($hc) ;
$hc->connect('tcp', $uri->host(), $uri->port()) ;
ok(1) ;
$hc->print("GET / HTTP/1.0\n\n") ;
ok(1) ;
my $data = $hc->read(1024) ;
if ($HTTunnel::Client::Test){
	ok($data) ;
}
else {
	ok($data, qr/This is the index.html file\./) ;
}

my $port = $uri->port() ;
ok($hc->get_peer_info(), qr/$port$/) ;
$hc->close() ;
ok(1) ;

# We must return 1 here since this file ls required by the Apache::HTTunnel
# test script.
1 ;
