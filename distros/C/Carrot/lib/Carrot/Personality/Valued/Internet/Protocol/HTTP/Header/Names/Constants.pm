package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Names::Constants
# /type class
# /attribute_type ::One_Anonymous::Scalar
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	sub HTTP_HEADER_ACCEPT() { 'Accept' }
	sub HTTP_HEADER_ACCEPT_CHARSET() { 'Accept-Charset' }
	sub HTTP_HEADER_ACCEPT_ENCODING() { 'Accept-Encoding' }
	sub HTTP_HEADER_ACCEPT_LANGUAGE() { 'Accept-Language' }
	sub HTTP_HEADER_ACCEPT_RANGES() { 'Accept-Ranges' }
	sub HTTP_HEADER_AGE() { 'Age' }
	sub HTTP_HEADER_ALLOW() { 'Allow' }
	sub HTTP_HEADER_AUTHORIZATION() { 'Authorization' }
	sub HTTP_HEADER_CACHE_CONTROL() { 'Cache-Control' }
	sub HTTP_HEADER_CONNECTION() { 'Connection' }
	sub HTTP_HEADER_CONTENT_ENCODING() { 'Content-Encoding' }
	sub HTTP_HEADER_CONTENT_LANGUAGE() { 'Content-Language' }
	sub HTTP_HEADER_CONTENT_LENGTH() { 'Content-Length' }
	sub HTTP_HEADER_CONTENT_LOCATION() { 'Content-Location' }
	sub HTTP_HEADER_CONTENT_MD5() { 'Content-MD5' }
	sub HTTP_HEADER_CONTENT_RANGE() { 'Content-Range' }
	sub HTTP_HEADER_CONTENT_TYPE() { 'Content-Type' }
	sub HTTP_HEADER_COOKIE() { 'Cookie' }
	sub HTTP_HEADER_DATE() { 'Date' }
	sub HTTP_HEADER_OPERATION() { 'Operation' }
	sub HTTP_HEADER_ETAG() { 'ETag' }
	sub HTTP_HEADER_EXPECT() { 'Expect' }
	sub HTTP_HEADER_EXPIRES() { 'Expires' }
	sub HTTP_HEADER_FROM() { 'From' }
	sub HTTP_HEADER_HOST() { 'Host' }
	sub HTTP_HEADER_IF_MATCH() { 'If-Match' }
	sub HTTP_HEADER_IF_MODIFIED_SINCE() { 'If-Modified-Since' }
	sub HTTP_HEADER_IF_NONE_MATCH() { 'If-None-Match' }
	sub HTTP_HEADER_IF_RANGE() { 'If-Range' }
	sub HTTP_HEADER_IF_UNMODIFIED_SINCE() { 'If-Unmodified-Since' }
	sub HTTP_HEADER_KEEP_ALIVE() { 'Keep-Alive' }
	sub HTTP_HEADER_LAST_MODIFIED() { 'Last-Modified' }
	sub HTTP_HEADER_LOCATION() { 'Location' }
	sub HTTP_HEADER_MAX_FORWARDS() { 'Max-Forwards' }
	sub HTTP_HEADER_PRAGMA() { 'Pragma' }
	sub HTTP_HEADER_PROXY_AUTHENTICATE() { 'Proxy-Authenticate' }
	sub HTTP_HEADER_PROXY_AUTHORIZATION() { 'Proxy-Authorization' }
	sub HTTP_HEADER_RANGE() { 'Range' }
	sub HTTP_HEADER_RANGES() { 'Ranges' }
	sub HTTP_HEADER_REQUESTS() { 'Requests' }
	sub HTTP_HEADER_REFERER() { 'Referer' }
	sub HTTP_HEADER_RETRY_AFTER() { 'Retry-After' }
	sub HTTP_HEADER_SERVER() { 'Server' }
	sub HTTP_HEADER_SET_COOKIE() { 'Set-Cookie' }
	sub HTTP_HEADER_SET_COOKIE2() { 'Set-Cookie2' }
	sub HTTP_HEADER_TE() { 'TE' }
	sub HTTP_HEADER_TRAILER() { 'Trailer' }
	sub HTTP_HEADER_TRANSFER_ENCODING() { 'Transfer-Encoding' }
	sub HTTP_HEADER_UPGRADE() { 'Upgrade' }
	sub HTTP_HEADER_USER_AGENT() { 'User-Agent' }
	sub HTTP_HEADER_VARY() { 'Vary' }
	sub HTTP_HEADER_VIA() { 'Via' }
	sub HTTP_HEADER_WARNING() { 'Warning' }
	sub HTTP_HEADER_WWW_AUTHENTICATE() { 'WWW-Authenticate' }

# =--------------------------------------------------------------------------= #

sub provide_constants
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @_;

	return('HTTP_HEADER_', [qw(
		ACCEPT
		ACCEPT_CHARSET
		ACCEPT_ENCODING
		ACCEPT_LANGUAGE
		ACCEPT_RANGES
		AGE
		ALLOW
		AUTHORIZATION
		CACHE_CONTROL
		CONNECTION
		CONTENT_ENCODING
		CONTENT_LANGUAGE
		CONTENT_LENGTH
		CONTENT_LOCATION
		CONTENT_MD5
		CONTENT_RANGE
		CONTENT_TYPE
		COOKIE
		DATE
		OPERATION
		ETAG
		EXPECT
		EXPIRES
		FROM
		HOST
		IF_MATCH
		IF_MODIFIED_SINCE
		IF_NONE_MATCH
		IF_RANGE
		IF_UNMODIFIED_SINCE
		KEEP_ALIVE
		LAST_MODIFIED
		LOCATION
		MAX_FORWARDS
		PRAGMA
		PROXY_AUTHENTICATE
		PROXY_AUTHORIZATION
		RANGE
		RANGES
		REQUESTS
		REFERER
		RETRY_AFTER
		SERVER
		SET_COOKIE
		SET_COOKIE2
		TE
		TRAILER
		TRANSFER_ENCODING
		UPGRADE
		USER_AGENT
		VARY
		VIA
		WARNING
		WWW_AUTHENTICATE)]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.48
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
