package Crop::HTTP::Session::Thru;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::HTTP::Session::Thru
	HTTP Session parameters to be passed to the next client request.

	Current handler have to passthrough user's parameters to the next request to
	restore form fields in the form next try.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:

	id_session - session <Crop::HTTP::Session> ID
	param      - param name
	value      - param value
=cut
our %Attributes = (
	id_session => {key => {extern => 'Crop::HTTP::Session'}},
	param      => {mode => 'read', key => 'text'},
	value      => {mode => 'read'},
);


=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'session_thru' string
=cut
sub Table { 'session_thru' }

1;
