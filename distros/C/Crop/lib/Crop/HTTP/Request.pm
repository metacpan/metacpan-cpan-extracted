package Crop::HTTP::Request;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::HTTP::Request
	HTTP request.

	Base class for particular gateways such FastCGI, PSGI, CGI.
	
	Attributes contain start and finish time besides regular HTTP data.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	content_t  - value of header Content-Type
	cookie_in  - cookie from client
	cookie_out - cookie to client
	fh         - hash contains file descriptors for upload
	headers    - HTTP headers from client; multiline string
	id_session - session
	ip         - client IP address, may be X-Real-IP from nginx
	method     - GET/POST/etc
	param      - parameters with their values, excluding upload fields; hashref
	path       - part of URL
	qstring    - Query String
	referer    - REFERER header separately
	tik        - start time mark as timestamp(6) with time zone
	tok        - finish time mark as timestamp(6) with time zone
=cut
our %Attributes = (
	content_t  => {mode => 'read', type => 'cache'},
	cookie_in  => {mode => 'read'},
	cookie_out => {mode => 'read/write'},
	fh         => {default => {}, type => 'cache'},
	headers    => undef,
	id_session => {mode => 'read/write'},
	ip         => undef,
	method     => undef,
	param      => {mode => 'read', default => {}, type=>'cache'},
	path       => undef,
	qstring    => undef,
	referer    => {mode => 'read'},
	tik        => {mode => 'read/write'},
	tok        => {mode => 'write'},
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'httprequest' string
=cut
sub Table { 'http' }

1;
