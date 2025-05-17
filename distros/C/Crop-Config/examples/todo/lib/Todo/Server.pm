package Todo::Server;
use base qw/ Crop::Server::FastCGI Exporter /;

=begin nd
Class: Todo::Server
	Specific Server for Todo
=cut

use v5.14;
use strict;

# get constants from base class, in contrast to get constants directly from <Crop::Server::Constatns>
Crop::Server->import(qw/ OK /);

=begin nd
Variable: our @EXPORT
	Export by default:
	
	- OK
=cut
our @EXPORT = qw/ OK /;

=begin nd
Method: _authenticate ( )
	Perform client autentication.
	
	Now is OFF.

Returns:
	1 - autentication successed
=cut
sub _authenticate {
	my $self = shift;
	
	1;
}

1;