package Crop;

=begin nd
Class: Crop
	The root of server gateway, and Object-relational mapping framework.
	
	Provides access to the config and Server instance from everywere.
=cut

use v5.14;
use warnings;

use Crop::Config;

=begin nd
Method: C ( )
	Get config data.
	
Returns:
	A hash of configuration values:
(start code)
config = {
	install => {
		path => '/home/cz/back/install',
	},
	warehouse => {
		db => {
			main => {
				name => 'cz',
				server => {
					host => 'localhost',
					port => 5432,
				},
				driver => 'Pg',
				role   => {
					admin => {
						login => 'cz_admin',
						pass  => 'secret1',
					},
					user => {
						pass  => 'cz_user',
						login => 'secret2',
					},
				},
			},
		},
		relation => {
			http => 'main',
			item => 'main',
		},
	},
	logLevel  => 'WARNING',
	debug => {
		layer => [
			'APP'
		],
		output => 'On'
	},
};
(end code)
=cut
sub C { Crop::Config->data }

=begin nd
Method: I_can (%privileges)
	Check Rights.
	
	All %privileges must present in current client Rights.
	
Parameters:
	%privileges - hash {READ => 'Crop', ...}
	
Returns:
	true  - if ok
	false - otherwise
=cut
sub I_can {
	my ($self, %priv) = @_;
	
	my $server = $Crop::Server::Server;
	
	$server->rights->ok(%priv);
}

=begin nd
Method: S ()
	Accessor to the <Crop::Server>.
	
	Since an access to database by Server class is imposible if code is not running by FastCGI:
> $self->S->D
	go to replace intermediate class to 'Crop' to get access by this top-level class.

Returns:
	Server object - if is running
	'Crop' string - otherwise

TODO:
	The D() method.
=cut
sub S { $Crop::Server::Server or 'Crop' }

1;
