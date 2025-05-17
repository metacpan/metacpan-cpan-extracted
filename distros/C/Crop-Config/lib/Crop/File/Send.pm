package Crop::File::Send;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::File::Send
	Sendfile feature.
	
	Nginx performs this action by a X-Accel-Redirect HTTP-header.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	disposition - how a browser must process the file received
	name       - "Content-Disposition" HTTP-header will show that name in a browser
	url         - private URL for Nginx inner redirect
=cut
our %Attributes = (
	disposition => {default => 'inline', mode => 'read'},
	name        => {mode => 'read/write'},
	url         => {mode => 'read'},
);

1;
