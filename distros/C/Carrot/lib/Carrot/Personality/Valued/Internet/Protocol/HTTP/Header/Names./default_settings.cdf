name	unknown_class
--------
flat    ::Valued::Perl::Package_Name::Wild
source  ::Source::Here::Plain
	::_Plain

name	default_class
--------
flat    ::Valued::Perl::Package_Name::Wild
source  ::Source::Here::Plain
	::_Plain

name	http_header_names
--------
table	::Structure::Table::Format::Concise_MxN::Unique name
source	::Source::Here::Plain
	*-----------------------+------+-------+----------------*
	| name                  | type | order | data_class     |
	+=======================+======+=======+================+
	| Accept                |  PQ  |   1   |                |
	| Accept-Charset        |  PQ  |   1   |                |
	| Accept-Encoding       |  PQ  |   1   |                |
	| Accept-Language       |  PQ  |   1   |                |
	| Accept-Ranges         |  PQ  |   1   |                |
	| Age                   |  PQ  |   1   |                |
	| Allow                 |  PQ  |   1   |                |
	| Authorization         |  PQ  |   1   |                |
	| Cache-Control         |  PQ  |   1   |                |
	| Connection            |  PQ  |   1   |                |
	| Content-Encoding      |  PQ  |   1   |                |
	| Content-Language      |  PQ  |   1   |                |
	| Content-Length        |  PQ  |   1   |                |
	| Content-Location      |  PQ  |   1   |                |
	| Content-MD5           |  PQ  |   1   |                |
	| Content-Range         |  PQ  |   1   |                |
	| Content-Type          |  PQ  |   1   |                |
	| Cookie                |  PQ  |   1   |                |
	| Date                  |  PQ  |   1   | ::RFC1123_Date |
	| Operation             |  PQ  |   1   |                |
	| ETag                  |  PQ  |   1   |                |
	| Expect                |  PQ  |   1   |                |
	| Expires               |  PQ  |   1   | ::RFC1123_Date |
	| From                  |  PQ  |   1   |                |
	| Host                  |  PQ  |   1   |                |
	| If-Match              |  PQ  |   1   |                |
	| If-Modified-Since     |  PQ  |   1   |                |
	| If-None-Match         |  PQ  |   1   |                |
	| If-Range              |  PQ  |   1   |                |
	| If-Unmodified-Since   |  PQ  |   1   |                |
	| Keep-Alive            |  PQ  |   1   |                |
	| Last-Modified         |  PQ  |   1   | ::RFC1123_Date |
	| Location              |  PQ  |   1   |                |
	| Max-Forwards          |  PQ  |   1   |                |
	| Pragma                |  PQ  |   1   |                |
	| Proxy-Authenticate    |  PQ  |   1   |                |
	| Proxy-Authorization   |  PQ  |   1   |                |
	| Range                 |  PQ  |   1   |                |
	| Ranges                |  PQ  |   1   |                |
	| Requests              |  PQ  |   1   |                |
	| Referer               |  PQ  |   1   |                |
	| Retry-After           |  PQ  |   1   |                |
	| Server                |  PQ  |   1   |                |
	| Set-Cookie            |  PQ  |   1   |                |
	| Set-Cookie2           |  PQ  |   1   |                |
	| TE                    |  PQ  |   1   |                |
	| Trailer               |  PQ  |   1   |                |
	| Transfer-Encoding     |  PQ  |   1   |                |
	| Upgrade               |  PQ  |   1   |                |
	| User-Agent            |  PQ  |   1   |                |
	| Vary                  |  PQ  |   1   |                |
	| Via                   |  PQ  |   1   |                |
	| Warning               |  PQ  |   1   |                |
	| WWW-Authenticate      |  PQ  |   1   |                |
	| X-Forwarded-For       |  PQ  |   1   |                |
	| X-Forwarded-Host      |  PQ  |   1   |                |
	| X-Forwarded-Server    |  PQ  |   1   |                |
	| X-Wap-Profile         |  PQ  |   1   |                |
	| X-Wap-Profile-Diff    |  PQ  |   1   |                |
	| X-Debug               |  PQ  |   1   |                |
	*-----------------------+------+-------+----------------*
column	::Valued::Text
column	::Valued::Text
column	::Valued::Number
column	::Valued::Text
