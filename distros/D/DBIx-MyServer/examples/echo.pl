
#
# This is a simple MySQL lisener that opens a listening socket on port $port. If DBIx::MyParse
# is installed, the query is parsed and the parse tree is returned to the client. If this module
# is not present, the query is simply echoed back to the client.
#

my $port = '23306';
my $database = 'myecho';
my $table = 'mytable';
my $field = 'myfield';

use strict;
use Socket;
use Data::Dumper;
$Data::Dumper::Terse = 1;

use DBIx::MyServer;

my $parser;
eval {
	require DBIx::MyParse;
	mkdir ("/tmp/".$database);
	$parser = DBIx::MyParse->new( datadir => "/tmp" );
	$parser->setDatabase($database);
};

socket(SERVER_SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
setsockopt(SERVER_SOCK, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
bind(SERVER_SOCK, sockaddr_in($port, INADDR_ANY)) || die "bind: $!";
listen(SERVER_SOCK,1);

print localtime()." [$$] Please use `mysql --host=127.0.0.1 --port=$port` to connect.\n";

while (1) {
	my $remote_paddr = accept(my $remote_socket, SERVER_SOCK);
	my $myserver = DBIx::MyServer->new( socket => $remote_socket );

	$myserver->sendServerHello();	# Those three together are identical to
	$myserver->readClientHello();	#	$myserver->handshake()
	$myserver->sendOK();		# which uses the default authorize() handler

	while (1) {
		my ($command, $data) = $myserver->readCommand();
		print localtime()." [$$] Command: $command; Data: $data\n";
		if (
			(not defined $command) ||
			($command == DBIx::MyServer::COM_QUIT)
		) {
			last;
		} elsif ($command == DBIx::MyServer::COM_QUERY) {
			$myserver->sendDefinitions([$myserver->newDefinition( name => 'field' )]);
			if ($data eq 'select @@version_comment limit 1') {
				$myserver->sendRows([[$0]]);	# Output script name
			} else {
				$myserver->sendRows([[defined $parser ? Dumper($parser->parse($data)) : $data]]);
			}
		} else {
			$myserver->sendErrorUnsupported($command);
		}
	}
}
