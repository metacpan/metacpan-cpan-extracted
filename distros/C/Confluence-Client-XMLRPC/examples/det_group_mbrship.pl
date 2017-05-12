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

my $users = $wiki->getActiveUsers('true');
foreach my $user (@$users) {
	my $groups = $wiki->getUserGroups($user);
	foreach my $group (@$groups) {
		print "$user is a member of $group\n";
	}
}

$wiki->logout();

