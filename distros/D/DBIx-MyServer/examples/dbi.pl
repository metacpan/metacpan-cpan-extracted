
#
# This is a simple MySQL lisener that opens a listening socket on port $port and forwards
# all queries to a DBI handle. This allows any DBI driver to be made accessible to ODBC clients via
# the MySQL ODBC driver

# Please note that this example accepts only one connection at a time, which may be a problem for applications
# that open multiple connections or forget to close existing ones. If you create a fork()-ing server, please
# do not forget to clone() your DBI handles before passing them to DBIx::MyParse->new()
#

use strict;
use Socket;

use DBIx::MyServer::DBI;

my $port = '23306';
socket(SERVER_SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
setsockopt(SERVER_SOCK, SOL_SOCKET, SO_REUSEADDR, pack("l", 1));
bind(SERVER_SOCK, sockaddr_in($port, INADDR_ANY)) || die "bind: $!";
listen(SERVER_SOCK,1);

while (1) {
	my $remote_paddr = accept(my $remote_socket, SERVER_SOCK);

	my $dbh = DBI->connect("DBI:mysql:");

	my $myserver = DBIx::MyServer::DBI->new(
		socket => $remote_socket,
		dbh => $dbh,
		banner => $dbh->get_info($DBI::Const::GetInfoType::GetInfoType{SQL_DBMS_VER})
	);

	last if not defined $myserver->handshake();

	while () {
		my $result = $myserver->processCommand();
		print localtime()." [$$] Query: $result\n";
		last if not defined $result;
	};
}
