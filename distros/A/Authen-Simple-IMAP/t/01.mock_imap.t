package My::Logger;

sub debug;
sub info;
sub error;
sub warn;
sub notice;
sub crit;
sub emerg;

sub AUTOLOAD {
	my $self = shift;
	print join(' ',@_)."\n";
}

package My::Fake::IMAP;

our $username = 'foo';
our $password = 'bar';

sub login {
	#print join(', ',@_)."\n";
	my $self = shift;
	my ($user,$pass) = @_;
	#print "User = $user\n";
	#print "Password = $pass\n";
	if ( $user eq $My::Fake::IMAP::username &&
	 	 $pass eq $My::Fake::IMAP::password )
	{
		return 1;
	}
	return 0;
}

sub errstr {
	return "authentication failed";
}

package main;

use Test::More tests => 5;
use Carp;
use Net::IMAP::Simple;

use_ok( 'Authen::Simple::IMAP' ) || BAIL_OUT('Can\'t test if we can\'t load');

my $logger = {};
bless($logger,'My::Logger');

my $fake_imap = {};
bless($fake_imap,'My::Fake::IMAP') || die 'Failed making fake imap object';

my $auth = Authen::Simple::IMAP->new(
	imap => $fake_imap, log => $logger );

my $result = eval { $auth->authenticate('foo','bar') };
ok( !$@, 'do authentication' ) || diag $@;
ok( $result ,' authentication succeeded') || diag "result = '$result'";

$result = eval { $auth->authenticate('foo','wibble') };
ok( !$@, 'fail authentication' ) || diag $@;
ok( !$result ,' authentication should fail') || diag "result = '$result'";


