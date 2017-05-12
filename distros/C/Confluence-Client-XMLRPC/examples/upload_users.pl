#!perl 

use strict;
use warnings;

use lib qw(../lib);
use Confluence::Client::XMLRPC;

my ( $url, $adminuser, $adminpass ) = @ARGV;

die "Usage is $0 <url> <admin-user> <admin-password>\n"
	unless ( ( defined $url and $url =~ /\Ahttp/ )
	and ( defined $adminuser and $adminuser )
	and ( defined $adminpass and $adminpass ) );

my $wiki = Confluence::Client::XMLRPC->new( $url, $adminuser, $adminpass );
Confluence::Client::XMLRPC::setRaiseError(0);
Confluence::Client::XMLRPC::setPrintError(1);

while (<>) {
	chomp;
	my ( $username, $password, $email, $fullname, $groupname ) = split /,/;
	my $user = {
		name     => $username,
		fullname => $fullname,
		email    => $email
	};
	print "adding $username\n";
	$wiki->addUser( $user, $password );
	$wiki->addUserToGroup( $username, $groupname );
}

$wiki->logout();

